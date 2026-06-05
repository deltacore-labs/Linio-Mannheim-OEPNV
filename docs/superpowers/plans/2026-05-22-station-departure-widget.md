# Station Departure Widget — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neues konfigurierbares iOS Home Screen Widget, das aktuelle Abfahrten einer frei wählbaren Haltestelle in drei Größen (Small/Medium/Large) anzeigt.

**Architecture:** Das Widget-Extension-Target fetcht Abfahrten direkt per GraphQL (URLSession). Der Auth-Token und die GraphQL-URL werden von der Haupt-App in die App Group UserDefaults geschrieben. Die Station wählt der Nutzer per AppIntentConfiguration (langes Drücken → "Widget bearbeiten"). Zuletzt genutzte Stationen werden ebenfalls in die App Group gespiegelt, damit sie im Intent als Vorschläge erscheinen.

**Tech Stack:** SwiftUI, WidgetKit, AppIntents (iOS 16+), URLSession, UserDefaults (App Group `group.com.stefanfriedrich.rnvapp`)

---

## Dateiübersicht

| Datei | Aktion | Verantwortlichkeit |
|-------|--------|--------------------|
| `RNVLiveActivity/StationDepartureWidget.swift` | Neu erstellen | Widget komplett: Modell, Intent, Provider, Views |
| `Linio/AuthService.swift` | Ändern | Token + URL nach Login in App Group schreiben |
| `Linio/Content/StationPickerView.swift` | Ändern | Gewählte Stationen in App Group spiegeln |
| `RNVLiveActivity/RNVLiveActivityBundle.swift` | Ändern | `StationDepartureWidget()` registrieren |
| `Linio/Content/ContentView.swift` | Ändern | Widget-Reload bei App-Öffnung |
| `Linio/SharedModels.swift` | Ändern | Widget-Reload in `scheduleWidgetReload()` |
| `Linio.xcodeproj` | Manuell in Xcode | Neue Datei zum `RNVLiveActivity`-Target hinzufügen |

---

## Task 1: Token + GraphQL-URL bei Login in App Group schreiben

**Files:**
- Modify: `Linio/AuthService.swift`

### Kontext

`AuthService.performAuthentication()` setzt bei Erfolg `self.accessToken = token`. Das Widget braucht diesen Token in `UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp")`. Außerdem speichern wir die GraphQL-URL aus dem Info.plist, damit das Widget sie kennt.

- [ ] **Schritt 1: Token + URL in App Group schreiben — direkt nach `self.accessToken = token`**

In `AuthService.swift`, in der Methode `performAuthentication()`, direkt nach der Zeile `self.accessToken = token` einfügen:

```swift
// Token + URL für Widget in App Group speichern
let appGroupDefaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp")
appGroupDefaults?.set(token, forKey: "widgetAccessToken")
let graphqlURL = Bundle.main.object(forInfoDictionaryKey: "RNV_GRAPHQL_URL") as? String
    ?? "https://graphql-sandbox-dds.rnv-online.de/"
appGroupDefaults?.set(graphqlURL, forKey: "widgetGraphQLURL")
```

- [ ] **Schritt 2: Token bei Logout aus App Group löschen**

In `AuthService.logout()`, nach `accessToken = nil`:

```swift
let appGroupDefaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp")
appGroupDefaults?.removeObject(forKey: "widgetAccessToken")
```

- [ ] **Schritt 3: Commit**

```bash
git add Linio/AuthService.swift
git commit -m "feat: Token und GraphQL-URL bei Login in App Group schreiben (Widget-Vorbereitung)"
```

---

## Task 2: Zuletzt genutzte Stationen in App Group spiegeln

**Files:**
- Modify: `Linio/Content/StationPickerView.swift`

### Kontext

`StationPickerView.saveRecentStation(_:)` schreibt aktuell nur in `UserDefaults.standard`. Das Widget-Intent braucht diese Liste aus der App Group unter Key `"widgetRecentStations"`. Wir spiegeln die Liste zusätzlich dorthin — `UserDefaults.standard` bleibt unverändert.

- [ ] **Schritt 1: App Group Spiegelung in `saveRecentStation(_:)` hinzufügen**

In `StationPickerView.swift`, am Ende von `saveRecentStation(_:)` (nach dem bestehenden `UserDefaults.standard.set`-Aufruf):

```swift
// Stationen zusätzlich in App Group spiegeln (für Widget-Intent-Vorschläge)
if let groupDefaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp"),
   let data = try? JSONEncoder().encode(recents) {
    groupDefaults.set(data, forKey: "widgetRecentStations")
}
```

Die Variable `recents` ist bereits als `[Station]` im gleichen Scope vorhanden.

- [ ] **Schritt 2: Commit**

```bash
git add Linio/Content/StationPickerView.swift
git commit -m "feat: Recent Stations zusätzlich in App Group spiegeln (für Widget-Stationsauswahl)"
```

---

## Task 3: StationDepartureWidget.swift erstellen

**Files:**
- Create: `RNVLiveActivity/StationDepartureWidget.swift`

Dies ist das Herzstück. Die Datei enthält alles in einer Datei, analog zu `HomeScreenWidgets.swift`. Bestehende Typen `WidgetTheme`, `WidgetLineBadge`, `WidgetDataProvider` aus `HomeScreenWidgets.swift` werden direkt wiederverwendet (gleicher Target).

- [ ] **Schritt 1: Datei anlegen**

Neue Datei `RNVLiveActivity/StationDepartureWidget.swift` mit folgendem Inhalt erstellen:

```swift
//
//  StationDepartureWidget.swift
//  RNVLiveActivity
//
//  Konfigurierbares Abfahrtstafel-Widget für eine frei wählbare Haltestelle.
//

import WidgetKit
import SwiftUI
import AppIntents

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Datenmodell
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct WidgetDeparture: Codable {
    let serviceName: String
    let serviceType: String
    let destination: String
    let plannedTimeISO: String
    let realtimeTimeISO: String?
    let quayText: String?

    var delayMinutes: Int? {
        guard let rt = realtimeTimeISO,
              let pDate = WidgetDataProvider.parseISO8601(plannedTimeISO),
              let rDate = WidgetDataProvider.parseISO8601(rt) else { return nil }
        let diff = Int(rDate.timeIntervalSince(pDate) / 60)
        return diff > 0 ? diff : 0
    }

    var effectiveTimeISO: String {
        realtimeTimeISO ?? plannedTimeISO
    }
}

enum StationWidgetError: Equatable {
    case noToken, noStation, networkError
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - AppEntity: Station
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StationEntity: AppEntity, Codable {
    // Muss dieselben CodingKeys haben wie `Station` in der Haupt-App,
    // damit die in App Group gespeicherten [Station]-JSON-Daten decodiert werden.
    let globalID: String
    let longName: String
    let hafasID: String

    // AppEntity-Pflichtfelder
    var id: String { globalID }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Haltestelle")
    }
    static var defaultQuery = StationEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(longName)")
    }
}

struct StationEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [StationEntity] {
        loadSaved().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [StationEntity] {
        loadSaved()
    }

    private func loadSaved() -> [StationEntity] {
        guard let defaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp"),
              let data = defaults.data(forKey: "widgetRecentStations"),
              let stations = try? JSONDecoder().decode([StationEntity].self, from: data) else {
            return []
        }
        return stations
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Widget Configuration Intent
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StationSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Station wählen"
    static var description = IntentDescription("Wähle eine Haltestelle für die Abfahrtstafel.")

    @Parameter(title: "Haltestelle")
    var station: StationEntity?
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Timeline Entry
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StationDepartureEntry: TimelineEntry {
    let date: Date
    let configuration: StationSelectionIntent
    let stationName: String
    let departures: [WidgetDeparture]
    let errorState: StationWidgetError?
    let isPlaceholder: Bool
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Netzwerk-Service (schlanker GraphQL-Fetch für Widget)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct WidgetDepartureService {

    /// Gibt `nil` zurück wenn der Netzwerkaufruf fehlschlägt, `[]` wenn keine Abfahrten.
    static func fetch(hafasID: String, token: String, graphqlURL: String) async -> [WidgetDeparture]? {
        let safeID = sanitize(hafasID)
        let safeTime = sanitize(ISO8601DateFormatter().string(from: Date()))

        let query = """
        {
          station(id: "\(safeID)") {
            journeys(startTime: "\(safeTime)", first: 20) {
              elements {
                ... on Journey {
                  line { id }
                  boardStops: stops(onlyHafasID: "\(safeID)") {
                    plannedDeparture { isoString }
                    realtimeDeparture { isoString }
                    stop { globalID }
                  }
                  allStops: stops {
                    stop { name }
                  }
                }
              }
            }
          }
        }
        """

        guard let url = URL(string: graphqlURL) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let body = try? JSONSerialization.data(withJSONObject: ["query": query]) else { return nil }
        request.httpBody = body

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let stationObj = responseData["station"] as? [String: Any],
              let journeysObj = stationObj["journeys"] as? [String: Any],
              let elements = journeysObj["elements"] as? [[String: Any]] else { return nil }

        return elements.compactMap { parse(element: $0, hafasID: safeID) }
    }

    private static func parse(element: [String: Any], hafasID: String) -> WidgetDeparture? {
        guard let lineObj = element["line"] as? [String: Any],
              let lineID = lineObj["id"] as? String,
              let stopsArr = element["boardStops"] as? [[String: Any]],
              let firstStop = stopsArr.first,
              let plannedObj = firstStop["plannedDeparture"] as? [String: Any],
              let planned = plannedObj["isoString"] as? String,
              planned != "null", !planned.isEmpty else { return nil }

        let rtRaw = (firstStop["realtimeDeparture"] as? [String: Any])?["isoString"] as? String
        let realtime = (rtRaw == "null" || rtRaw?.isEmpty == true) ? nil : rtRaw

        // "rnv:64:H" → "64"
        let parts = lineID.split(separator: ":").map(String.init)
        let lineName = parts.count >= 2 ? parts[1] : lineID

        let serviceType: String = {
            let n = lineName.uppercased()
            if n.hasPrefix("S"), n.dropFirst().first?.isNumber == true { return "S_BAHN" }
            let numPrefix = n.prefix(while: { $0.isNumber })
            if !numPrefix.isEmpty, let num = Int(numPrefix), num >= 1, num <= 61 { return "STRASSENBAHN" }
            return "BUS"
        }()

        let allStops = element["allStops"] as? [[String: Any]] ?? []
        let destination = allStops.last.flatMap { ($0["stop"] as? [String: Any])?["name"] as? String } ?? ""

        let stopGlobalID = (firstStop["stop"] as? [String: Any])?["globalID"] as? String
        let quayText = stopGlobalID.flatMap { extractQuayText(from: $0) }

        return WidgetDeparture(
            serviceName: lineName,
            serviceType: serviceType,
            destination: destination,
            plannedTimeISO: planned,
            realtimeTimeISO: realtime,
            quayText: quayText
        )
    }

    // Gleiche Logik wie StationQuay.quayText(fromRef:) in GraphQLService.swift
    private static func extractQuayText(from ref: String) -> String? {
        let parts = ref.split(separator: ":")
        guard parts.count >= 5 else { return nil }
        let segment = String(parts[4])
        guard !segment.isEmpty, segment != "0", segment != "null" else { return nil }
        guard segment.range(of: #"^[A-Z]{1,2}[0-9]?$|^[0-9]{1,3}$"#, options: .regularExpression) != nil else { return nil }
        return "Steig \(segment)"
    }

    private static func sanitize(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\n", with: " ")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Timeline Provider
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StationDepartureProvider: AppIntentTimelineProvider {
    typealias Entry = StationDepartureEntry
    typealias Intent = StationSelectionIntent

    func placeholder(in context: Context) -> StationDepartureEntry {
        StationDepartureEntry(
            date: Date(),
            configuration: StationSelectionIntent(),
            stationName: "Mannheim Hbf",
            departures: StationWidgetPreviewData.sampleDepartures,
            errorState: nil,
            isPlaceholder: true
        )
    }

    func snapshot(for configuration: StationSelectionIntent, in context: Context) async -> StationDepartureEntry {
        StationDepartureEntry(
            date: Date(),
            configuration: configuration,
            stationName: configuration.station?.longName ?? "Mannheim Hbf",
            departures: StationWidgetPreviewData.sampleDepartures,
            errorState: nil,
            isPlaceholder: false
        )
    }

    func timeline(for configuration: StationSelectionIntent, in context: Context) async -> Timeline<StationDepartureEntry> {
        let entry = await buildEntry(for: configuration)
        let nextRefresh = Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func buildEntry(for configuration: StationSelectionIntent) async -> StationDepartureEntry {
        let defaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp")

        guard let token = defaults?.string(forKey: "widgetAccessToken"), !token.isEmpty else {
            return StationDepartureEntry(
                date: Date(), configuration: configuration,
                stationName: "—", departures: [], errorState: .noToken, isPlaceholder: false
            )
        }

        guard let station = configuration.station else {
            return StationDepartureEntry(
                date: Date(), configuration: configuration,
                stationName: "—", departures: [], errorState: .noStation, isPlaceholder: false
            )
        }

        let graphqlURL = defaults?.string(forKey: "widgetGraphQLURL")
            ?? "https://graphql-sandbox-dds.rnv-online.de/"

        let result = await WidgetDepartureService.fetch(
            hafasID: station.hafasID,
            token: token,
            graphqlURL: graphqlURL
        )

        return StationDepartureEntry(
            date: Date(),
            configuration: configuration,
            stationName: station.longName,
            departures: result ?? [],
            errorState: result == nil ? .networkError : nil,
            isPlaceholder: false
        )
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Views
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// Wiederverwendbare Abfahrtszeile
private struct DepartureRow: View {
    let dep: WidgetDeparture
    let currentDate: Date

    private var minutesUntil: Int {
        guard let d = WidgetDataProvider.parseISO8601(dep.effectiveTimeISO) else { return 0 }
        return max(0, Int(d.timeIntervalSince(currentDate) / 60))
    }

    var body: some View {
        HStack(spacing: 8) {
            WidgetLineBadge(serviceType: dep.serviceType, serviceName: dep.serviceName, compact: true)

            Text(dep.destination)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            departureTime
        }
    }

    @ViewBuilder
    private var departureTime: some View {
        if let delay = dep.delayMinutes, delay > 0 {
            HStack(spacing: 3) {
                Text(WidgetDataProvider.formatTime(dep.plannedTimeISO))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .strikethrough()
                    .foregroundColor(.secondary)
                Text(WidgetDataProvider.formatTime(dep.effectiveTimeISO))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }
        } else {
            Text("\(minutesUntil)'")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(WidgetTheme.primaryColor)
                .frame(minWidth: 28, alignment: .trailing)
        }
    }
}

// Kopfzeile (Station + Uhrzeit)
private struct StationHeader: View {
    let stationName: String
    let currentDate: Date

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.primaryColor)
                Text(stationName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(WidgetDataProvider.timeFormatter.string(from: currentDate))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: Small View

struct StationDepartureSmallView: View {
    let entry: StationDepartureEntry

    var body: some View {
        if entry.isPlaceholder {
            placeholderView
        } else if let error = entry.errorState {
            errorView(error)
        } else if let dep = entry.departures.first {
            departureView(dep)
        } else {
            emptyView
        }
    }

    private func departureView(_ dep: WidgetDeparture) -> some View {
        let mins = max(0, WidgetDataProvider.parseISO8601(dep.effectiveTimeISO)
            .map { Int($0.timeIntervalSince(entry.date) / 60) } ?? 0)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WidgetTheme.primaryColor)
                Text(entry.stationName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            WidgetLineBadge(serviceType: dep.serviceType, serviceName: dep.serviceName)

            Spacer().frame(height: 6)

            Text(dep.destination)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)

            Spacer()

            HStack(alignment: .bottom) {
                if let delay = dep.delayMinutes, delay > 0 {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(WidgetDataProvider.formatTime(dep.plannedTimeISO))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        Text(WidgetDataProvider.formatTime(dep.effectiveTimeISO))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                } else {
                    Text(WidgetDataProvider.formatTime(dep.effectiveTimeISO))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("\(max(0, mins))'")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(WidgetTheme.primaryColor)
            }
        }
        .padding(14)
    }

    private var placeholderView: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(width: 80, height: 10)
            Spacer()
            RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.2)).frame(width: 48, height: 24)
            RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.12)).frame(height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)).frame(height: 18)
        }
        .padding(14)
    }

    private func errorView(_ error: StationWidgetError) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: errorIcon(error))
                .font(.system(size: 24))
                .foregroundStyle(WidgetTheme.primaryColor.opacity(0.4))
            Text(errorText(error))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(14)
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "tram.fill")
                .font(.system(size: 22))
                .foregroundStyle(WidgetTheme.primaryColor.opacity(0.3))
            Text("Keine\nAbfahrten")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(14)
    }
}

// MARK: Medium View

struct StationDepartureMediumView: View {
    let entry: StationDepartureEntry

    var body: some View {
        if let error = entry.errorState {
            errorMediumView(error)
        } else {
            contentView
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 7) {
            StationHeader(stationName: entry.stationName, currentDate: entry.date)
            Divider()

            if entry.departures.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Keine Abfahrten in den nächsten 60 min")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(Array(entry.departures.prefix(3).enumerated()), id: \.offset) { _, dep in
                    DepartureRow(dep: dep, currentDate: entry.date)
                }
            }

        }
        .padding(14)
    }

    private func errorMediumView(_ error: StationWidgetError) -> some View {
        HStack(spacing: 12) {
            Image(systemName: errorIcon(error))
                .font(.system(size: 28))
                .foregroundStyle(WidgetTheme.primaryColor.opacity(0.35))
            VStack(alignment: .leading, spacing: 4) {
                Text(errorText(error))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
    }
}

// MARK: Large View

struct StationDepartureLargeView: View {
    let entry: StationDepartureEntry

    var body: some View {
        if let error = entry.errorState {
            errorLargeView(error)
        } else {
            contentView
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(WidgetTheme.accentGradient)
                        .frame(width: 32, height: 32)
                    Image(systemName: "tram.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.stationName)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    Text("Abfahrten")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(WidgetDataProvider.timeFormatter.string(from: entry.date))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 8)

            Divider()

            if entry.departures.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 28))
                            .foregroundStyle(WidgetTheme.primaryColor.opacity(0.3))
                        Text("Keine Abfahrten in den\nnächsten 60 min")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(Array(entry.departures.prefix(6).enumerated()), id: \.offset) { index, dep in
                    DepartureRow(dep: dep, currentDate: entry.date)
                        .padding(.vertical, 6)
                    if index < min(entry.departures.count - 1, 5) {
                        Divider()
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private func errorLargeView(_ error: StationWidgetError) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: errorIcon(error))
                .font(.system(size: 36))
                .foregroundStyle(WidgetTheme.primaryColor.opacity(0.3))
            Text(errorText(error))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(14)
    }
}

// MARK: Container + Helpers

struct StationDepartureContainerView: View {
    @Environment(\.widgetFamily) var family
    let entry: StationDepartureEntry

    var body: some View {
        switch family {
        case .systemLarge:  StationDepartureLargeView(entry: entry)
        case .systemMedium: StationDepartureMediumView(entry: entry)
        default:            StationDepartureSmallView(entry: entry)
        }
    }
}

private func errorIcon(_ error: StationWidgetError) -> String {
    switch error {
    case .noToken:   return "lock.fill"
    case .noStation: return "mappin.slash"
    case .networkError: return "wifi.slash"
    }
}

private func errorText(_ error: StationWidgetError) -> String {
    switch error {
    case .noToken:   return "Bitte App öffnen\nund anmelden"
    case .noStation: return "Station konfigurieren\n(Widget lange drücken)"
    case .networkError: return "Keine Verbindung"
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Widget Definition
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StationDepartureWidget: Widget {
    let kind = "StationDepartureWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StationSelectionIntent.self,
            provider: StationDepartureProvider()
        ) { entry in
            if #available(iOS 17.0, *) {
                StationDepartureContainerView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StationDepartureContainerView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Abfahrtstafel")
        .description("Zeigt aktuelle Abfahrten einer Haltestelle.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Vorschau-Daten
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum StationWidgetPreviewData {
    static let sampleDepartures: [WidgetDeparture] = [
        WidgetDeparture(
            serviceName: "5", serviceType: "STRASSENBAHN", destination: "Heidelberg Hbf",
            plannedTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(180)),
            realtimeTimeISO: nil, quayText: "Steig A"
        ),
        WidgetDeparture(
            serviceName: "33", serviceType: "BUS", destination: "Neustadt",
            plannedTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(720)),
            realtimeTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(840)),
            quayText: nil
        ),
        WidgetDeparture(
            serviceName: "5A", serviceType: "STRASSENBAHN", destination: "Käfertal",
            plannedTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(1080)),
            realtimeTimeISO: nil, quayText: "Steig B"
        ),
        WidgetDeparture(
            serviceName: "1", serviceType: "STRASSENBAHN", destination: "Schönau",
            plannedTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(1440)),
            realtimeTimeISO: nil, quayText: nil
        ),
        WidgetDeparture(
            serviceName: "S1", serviceType: "S_BAHN", destination: "Frankfurt Hbf",
            plannedTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(1860)),
            realtimeTimeISO: nil, quayText: "Steig 3"
        ),
        WidgetDeparture(
            serviceName: "63", serviceType: "BUS", destination: "Seckenheim",
            plannedTimeISO: ISO8601DateFormatter().string(from: Date().addingTimeInterval(2340)),
            realtimeTimeISO: nil, quayText: nil
        ),
    ]
}
```

- [ ] **Schritt 2: Prüfen dass `WidgetDataProvider.timeFormatter` public ist**

In `HomeScreenWidgets.swift` ist `timeFormatter` als `private static let` deklariert. Es wird in `StationDepartureWidget.swift` (gleicher Target) benötigt. Prüfe ob der Zugriff kompiliert. Falls nicht: `private` → `static let` (internal) ändern. Suche in `HomeScreenWidgets.swift`:

```swift
// Vorher:
private static let timeFormatter: DateFormatter = {

// Nachher (internal, kein `private`):
static let timeFormatter: DateFormatter = {
```

- [ ] **Schritt 3: Commit**

```bash
git add RNVLiveActivity/StationDepartureWidget.swift
git commit -m "feat: StationDepartureWidget — AppIntentConfiguration, Small/Medium/Large Views, direkter GraphQL-Fetch"
```

---

## Task 4: Widget im Bundle registrieren + Xcode-Target

**Files:**
- Modify: `RNVLiveActivity/RNVLiveActivityBundle.swift`
- Manuell: Xcode Projekt

- [ ] **Schritt 1: Widget zum Bundle hinzufügen**

In `RNVLiveActivityBundle.swift`:

```swift
// Vorher:
var body: some Widget {
    RNVLiveActivityLiveActivity()
    NextDepartureWidget()
    ActiveTripsWidget()
    QuickSearchWidget()
}

// Nachher:
var body: some Widget {
    RNVLiveActivityLiveActivity()
    NextDepartureWidget()
    ActiveTripsWidget()
    QuickSearchWidget()
    StationDepartureWidget()
}
```

- [ ] **Schritt 2: Datei in Xcode zum Target hinzufügen**

In Xcode:
1. `StationDepartureWidget.swift` im Finder auf den Ordner `RNVLiveActivity` ziehen (oder Rechtsklick → Add Files to...).
2. Im Dialog sicherstellen dass **nur** das Target `RNVLiveActivity` angehakt ist (nicht das Haupt-App-Target).
3. Prüfen im Target → Build Phases → Compile Sources: `StationDepartureWidget.swift` muss unter `RNVLiveActivity` erscheinen.

- [ ] **Schritt 3: Build-Test (Compile only)**

```
In Xcode: Product → Build (⌘B)
Erwartetes Ergebnis: Build Succeeded, keine Fehler
```

- [ ] **Schritt 4: Commit**

```bash
git add RNVLiveActivity/RNVLiveActivityBundle.swift "Linio.xcodeproj/project.pbxproj"
git commit -m "feat: StationDepartureWidget im WidgetBundle registriert"
```

---

## Task 5: Widget-Reload bei App-Öffnung + Token-Erneuerung

**Files:**
- Modify: `Linio/Content/ContentView.swift`
- Modify: `Linio/SharedModels.swift`

- [ ] **Schritt 1: Reload nach `autoAuthenticate()` in ContentView**

In `ContentView.swift`, im `.task`-Block, direkt nach `await authService.autoAuthenticate()`:

```swift
.task {
    await authService.autoAuthenticate()
    WidgetCenter.shared.reloadTimelines(ofKind: "StationDepartureWidget")  // NEU
    await locationManager.autoRequestLocation()
}
```

Dazu `import WidgetKit` am Dateianfang ergänzen falls noch nicht vorhanden.

- [ ] **Schritt 2: Reload in scheduleWidgetReload() ergänzen**

In `SharedModels.swift`, in der Methode `scheduleWidgetReload()` (wo bereits andere Widget-Reloads stehen):

```swift
// Bestehende Zeilen:
WidgetCenter.shared.reloadTimelines(ofKind: "NextDepartureWidget")
WidgetCenter.shared.reloadTimelines(ofKind: "ActiveTripsWidget")
WidgetCenter.shared.reloadTimelines(ofKind: "QuickSearchWidget")
// NEU:
WidgetCenter.shared.reloadTimelines(ofKind: "StationDepartureWidget")
```

- [ ] **Schritt 3: Build-Test**

```
In Xcode: Product → Build (⌘B)
Erwartetes Ergebnis: Build Succeeded
```

- [ ] **Schritt 4: Commit**

```bash
git add Linio/Content/ContentView.swift Linio/SharedModels.swift
git commit -m "feat: StationDepartureWidget-Reload bei App-Öffnung und Token-Erneuerung"
```

---

## Task 6: Manueller Funktionstest auf Gerät

- [ ] **Schritt 1: App auf Gerät installieren**

```
In Xcode: Product → Run (⌘R) auf physischem iPhone
```

- [ ] **Schritt 2: In der App anmelden und eine Station aufrufen**

1. App öffnen → automatische Anmeldung abwarten.
2. Tab "Abfahrten" öffnen → eine Station (z.B. "Mannheim Hbf") auswählen → Abfahrten laden.
3. Dadurch werden Token und Station in die App Group geschrieben.

- [ ] **Schritt 3: Widget auf Home Screen hinzufügen**

1. Home Screen → lange drücken → Widget hinzufügen → "ÖPNV Mannheim" suchen.
2. Widget "Abfahrtstafel" in den drei Größen sichtbar?
3. Medium-Widget hinzufügen → "Widget bearbeiten" (langes Drücken) → Haltestelle auswählen.
4. Erwartetes Ergebnis: Zuletzt genutzte Station erscheint als Vorschlag.

- [ ] **Schritt 4: Abfahrten prüfen**

- Widget zeigt Abfahrtszeilen mit korrekten Linien und Richtungen.
- Minutenanzeige stimmt mit aktueller Uhrzeit überein.
- Small zeigt 1 Abfahrt, Medium 3, Large 6.

- [ ] **Schritt 5: Fehlerzustand testen**

- Logout in der App → Widget neu laden → "Bitte App öffnen und anmelden" erscheint.

---

## Bekannte Einschränkungen

- **Stationsauswahl nur aus zuletzt genutzten Stationen:** Da kein eigener Such-Endpunkt im Widget läuft, erscheinen als Vorschläge nur Stationen die vorher in der App gesucht wurden. Erst nach erstem App-Start mit Stationssuche sind Vorschläge verfügbar.
- **Token-Ablauf:** Das Widget merkt nicht aktiv, dass der Token abgelaufen ist — es zeigt dann einen `.networkError`-Zustand. Beim nächsten App-Öffnen wird der Token erneuert und der Widget-Reload ausgelöst.
