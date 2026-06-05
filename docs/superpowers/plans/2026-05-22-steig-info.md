# Steig-Info mit MapKit-Sheet — Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Jede Abfahrtszeile zeigt einen tippbaren Steig-Badge; Tap öffnet ein Sheet mit MapKit-Karte (alle Steige als Pins, gesuchter Steig orange) und gefilterten Abfahrten von diesem Steig.

**Architecture:** `quayText` wird beim Parsen der API-Antwort befüllt — primär aus `stop.globalID` im Journeys-Pfad, sekundär aus `board.point.ref` im Hub-Fallback-Pfad. Koordinaten für die Karte kommen aus einem neuen `getStationQuays()`-API-Call der beim Sheet-Öffnen lazy lädt. `SteigSheet` ist eine neue View-Datei; `DepartureRowView` bekommt einen optionalen `onSteigTap`-Callback.

**Tech Stack:** SwiftUI, MapKit (iOS 17 `Map` + `Annotation`), GraphQL (bestehender `GraphQLService`)

---

### Task 1: `StationQuay`-Model, Parsing-Helper und `quayText` auf `Departure`

**Files:**
- Modify: `Linio/GraphQLService.swift` — neues Struct nach `OccupancyLevel`
- Modify: `Linio/Content/DepartureBoardView.swift` — neues Feld in `Departure`

- [ ] **Schritt 1: `StationQuay` Struct und Parsing-Helper in `GraphQLService.swift` einfügen**

Direkt nach dem `OccupancyLevel`-Enum (ca. Zeile 100) einfügen:

```swift
// MARK: - StationQuay

struct StationQuay: Identifiable {
    let id: String       // hafasID des Einzelhaltepunkts
    let name: String     // z.B. "MA Hauptbahnhof, Steig A"
    let letter: String   // z.B. "A"
    let coordinate: CLLocationCoordinate2D

    /// Extrahiert den Steig-Buchstaben aus einem HAFAS-Ref-String.
    /// Format: "de:08222:2505:3:A" → "Steig A"
    /// Gibt nil zurück wenn kein Platform-Segment vorhanden oder leer/null.
    static func quayText(fromRef ref: String) -> String? {
        let parts = ref.split(separator: ":")
        guard parts.count >= 5 else { return nil }
        let segment = String(parts[4])
        guard !segment.isEmpty, segment != "0", segment != "null" else { return nil }
        return "Steig \(segment)"
    }

    /// Extrahiert den Buchstaben aus dem letzten Wort des Namens.
    /// "MA Hauptbahnhof, Steig A" → "A"
    static func letter(fromName name: String) -> String {
        String(name.split(separator: " ").last ?? Substring(name.prefix(1)))
    }
}
```

`CLLocationCoordinate2D` erfordert `import CoreLocation` — das ist in `GraphQLService.swift` noch nicht importiert. Ganz oben hinzufügen (nach `import Foundation`):

```swift
import CoreLocation
```

- [ ] **Schritt 2: `quayText` Feld in `Departure` hinzufügen**

In `DepartureBoardView.swift`, im `Departure`-Struct (ca. Zeile 541), nach `var occupancy: OccupancyLevel? = nil` einfügen:

```swift
var quayText: String? = nil  // z.B. "Steig A", nil → Badge ausgeblendet
```

- [ ] **Schritt 3: Projekt bauen (⌘B) — muss fehlerfrei sein**

Erwartetes Ergebnis: Build Succeeded. Kein neues Code-Verhalten, nur neue Typen/Felder.

- [ ] **Schritt 4: Commit**

```bash
git add Linio/GraphQLService.swift Linio/Content/DepartureBoardView.swift
git commit -m "feat: StationQuay-Model, quayText-Parsing-Helper und quayText-Feld auf Departure"
```

---

### Task 2: `quayText` im Journeys-Pfad befüllen

**Files:**
- Modify: `Linio/GraphQLService.swift` — Methode `getDeparturesViaJourneys`

Der Journeys-Pfad ist der primäre Ladeweg. Er muss `stop { globalID }` pro Haltepunkt abfragen, damit wir daraus den Steig-Buchstaben ableiten können.

- [ ] **Schritt 1: Query in `getDeparturesViaJourneys` erweitern**

In der Methode `getDeparturesViaJourneys` (ca. Zeile 1071), den `boardStops`-Block im Query von:

```graphql
boardStops: stops(onlyHafasID: "\(safeID)") {
    plannedDeparture {
        isoString
    }
    realtimeDeparture {
        isoString
    }
}
```

auf:

```graphql
boardStops: stops(onlyHafasID: "\(safeID)") {
    plannedDeparture {
        isoString
    }
    realtimeDeparture {
        isoString
    }
    stop {
        globalID
    }
}
```

- [ ] **Schritt 2: `quayText` beim Parsen der Journeys-Antwort extrahieren**

Im `compactMap`-Block (ca. Zeile 1131), nach dem Berechnen von `effectiveRealtime` und vor dem `return Departure(...)`:

Aktuell steht dort:
```swift
return Departure(
    scheduledDeparture: planned,
    estimatedDeparture: effectiveRealtime,
    lineName: lineName,
    direction: destinationName,
    serviceType: serviceType,
    occupancy: occupancy
)
```

Ersetzen durch:
```swift
let stopGlobalID = (firstStop["stop"] as? [String: Any])?["globalID"] as? String
let quayText = stopGlobalID.flatMap { StationQuay.quayText(fromRef: $0) }
plog("getDeparturesViaJourneys: Linie \(lineName) globalID=\(stopGlobalID ?? "–") quayText=\(quayText ?? "–")")

var departure = Departure(
    scheduledDeparture: planned,
    estimatedDeparture: effectiveRealtime,
    lineName: lineName,
    direction: destinationName,
    serviceType: serviceType,
    occupancy: occupancy
)
departure.quayText = quayText
return departure
```

- [ ] **Schritt 3: Bauen (⌘B) — muss fehlerfrei sein**

- [ ] **Schritt 4: App starten, Debug-Konsole prüfen**

Suche nach Logzeilen `getDeparturesViaJourneys: Linie X globalID=... quayText=...`

- Falls `quayText=Steig A` erscheint → API liefert globalID mit Platform-Segment ✓
- Falls `quayText=–` erscheint → API liefert globalID ohne Platform-Segment (z.B. nur `de:08222:2505`). Das ist kein Fehler — der Hub-Fallback-Pfad (Task 3) und statische Zuordnung sind dann nötig.

- [ ] **Schritt 5: Commit**

```bash
git add Linio/GraphQLService.swift
git commit -m "feat: quayText aus stop.globalID im Journeys-Abfahrts-Pfad"
```

---

### Task 3: `quayText` im Hub-Fallback-Pfad befüllen

**Files:**
- Modify: `Linio/GraphQLService.swift` — Methode `fetchFirstLegsAsDepartures`

Der Hub-Fallback nutzt `trips { legs { board { point { ... } } } }`. Hier können wir `ref` auf `StopPoint` abfragen.

- [ ] **Schritt 1: `ref` zum Query in `fetchFirstLegsAsDepartures` hinzufügen**

In `fetchFirstLegsAsDepartures` (ca. Zeile 922), den board-Block von:

```graphql
board {
    point {
        ... on StopPoint {
            stopPointName
        }
    }
    timetabledTime { isoString }
    estimatedTime { isoString }
}
```

auf:

```graphql
board {
    point {
        ... on StopPoint {
            stopPointName
            ref
        }
    }
    timetabledTime { isoString }
    estimatedTime { isoString }
}
```

- [ ] **Schritt 2: `quayText` beim Konstruieren der `Departure` setzen**

Im `compactMap`-Block (ca. Zeile 979), nach `let rawBoardStop = ...` und vor `return Departure(...)`:

```swift
let boardRef = (board["point"] as? [String: Any])?["ref"] as? String
let quayText = boardRef.flatMap { StationQuay.quayText(fromRef: $0) }
```

Dann im `return Departure(...)` (ca. Zeile 1015):

```swift
var departure = Departure(
    scheduledDeparture: timetabled,
    estimatedDeparture: (estimated == "null") ? nil : estimated,
    lineName: lineName,
    direction: direction,
    serviceType: service["type"] as? String,
    boardStopName: boardStopName,
    intermediateStops: intermediateStops,
    finalStop: finalStop
)
departure.quayText = quayText
return departure
```

**Hinweis:** Die Zeile mit `return Departure(...)` endet aktuell mit einem trailing-comma nach `finalStop` — ggf. `originGlobalID` o.ä. folgen noch. Nur das `quayText`-Assignment davor einfügen, das Konstruktor-Tupel nicht ändern.

- [ ] **Schritt 3: Bauen (⌘B) — muss fehlerfrei sein**

- [ ] **Schritt 4: Commit**

```bash
git add Linio/GraphQLService.swift
git commit -m "feat: quayText aus board.point.ref im Hub-Fallback-Abfahrts-Pfad"
```

---

### Task 4: `getStationQuays()` in `GraphQLService`

**Files:**
- Modify: `Linio/GraphQLService.swift` — neue Methode

- [ ] **Schritt 1: Methode `getStationQuays` einfügen**

Direkt vor der letzten `}` der Klasse `GraphQLService` (ganz am Ende der Datei) einfügen:

```swift
// MARK: - Station Quays (Koordinaten pro Steig)

func getStationQuays(hafasID: String, accessToken: String) async -> [StationQuay] {
    let safeID = sanitize(hafasID)
    let query = """
    {
      station(id: "\(safeID)") {
        stops {
          hafasID
          name
          lat
          lon
        }
      }
    }
    """

    guard let data = try? await executeQuery(query: query, accessToken: accessToken),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let responseData = json["data"] as? [String: Any],
          let stationObj = responseData["station"] as? [String: Any],
          let stopsArr = stationObj["stops"] as? [[String: Any]]
    else {
        plog("getStationQuays: Keine Stop-Daten für hafasID=\(hafasID)")
        return []
    }

    let quays: [StationQuay] = stopsArr.compactMap { stop in
        guard let hid = stop["hafasID"] as? String,
              let name = stop["name"] as? String,
              let lat = stop["lat"] as? Double,
              let lon = stop["lon"] as? Double,
              lat != 0, lon != 0 else { return nil }
        let letter = StationQuay.letter(fromName: name)
        return StationQuay(
            id: hid,
            name: name,
            letter: letter,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
        )
    }

    plog("getStationQuays: \(quays.count) Steige für hafasID=\(hafasID)")
    return quays
}
```

- [ ] **Schritt 2: Bauen (⌘B) — muss fehlerfrei sein**

- [ ] **Schritt 3: Commit**

```bash
git add Linio/GraphQLService.swift
git commit -m "feat: getStationQuays() lädt Steig-Koordinaten per Station"
```

---

### Task 5: Steig-Badge in `DepartureRowView` + Sheet-Trigger in `DepartureBoardView`

**Files:**
- Modify: `Linio/Content/DepartureBoardView.swift`

- [ ] **Schritt 1: `onSteigTap`-Callback zu `DepartureRowView` hinzufügen**

In `DepartureRowView` (ca. Zeile 446), die Properties ergänzen:

```swift
struct DepartureRowView: View {
    let departure: Departure
    var onSteigTap: (() -> Void)? = nil   // ← neu
    private let formatter = DateFormattingHelper.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
```

- [ ] **Schritt 2: Steig-Badge in `DepartureRowView.body` einfügen**

Im `HStack` von `DepartureRowView.body` (ca. Zeile 452), direkt vor dem `Spacer()` das Occupancy-Badge einbettet, das Badge einfügen. Der Block sieht aktuell so aus:

```swift
HStack(spacing: 16) {
    lineBadge
    VStack(alignment: .leading, spacing: 2) { ... }
    Spacer()
    occupancyBadge(departure.occupancy ?? .low)
    VStack(alignment: .trailing, spacing: 2) { ... }
}
```

Nach `VStack(alignment: .trailing, spacing: 2) { ... }` einfügen:

```swift
if let quayText = departure.quayText, let tap = onSteigTap {
    Button(action: tap) {
        Text(quayText)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(AppTheme.canvasAdaptive(colorScheme).opacity(0.0))
            .foregroundColor(AppTheme.muted)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppTheme.muted.opacity(0.4), lineWidth: 1)
            )
    }
    .buttonStyle(.plain)
}
```

- [ ] **Schritt 3: `selectedSteigDeparture` State und Sheet in `DepartureBoardView` hinzufügen**

In `DepartureBoardView`, bei den `@State`-Properties (ca. Zeile 17), hinzufügen:

```swift
@State private var selectedSteigDeparture: Departure?
```

In der View, dort wo das bestehende `.sheet(item: $selectedDeparture)` steht (ca. Zeile 106), danach ein zweites Sheet hinzufügen:

```swift
.sheet(item: $selectedSteigDeparture) { dep in
    if let station = selectedStation {
        SteigSheet(
            departure: dep,
            allDepartures: departures,
            station: station,
            graphQLService: service,
            authService: authService
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
```

- [ ] **Schritt 4: `onSteigTap` beim Rendern der Departure-Zeilen übergeben**

Die Departure-Liste rendert aktuell (ca. Zeile 226):

```swift
Button {
    // …bestehende Tap-Logik…
} label: {
    DepartureRowView(departure: dep)
}
.buttonStyle(.plain)
```

Ersetzen durch:

```swift
Button {
    // …bestehende Tap-Logik…
} label: {
    DepartureRowView(departure: dep, onSteigTap: { selectedSteigDeparture = dep })
}
.buttonStyle(.plain)
```

- [ ] **Schritt 5: Nicht committen — weiter mit Task 6**

`SteigSheet` existiert noch nicht → Build schlägt mit „Cannot find type 'SteigSheet'" fehl. Das ist erwartet. Temporär das `.sheet(item: $selectedSteigDeparture)`-Sheet auskommentieren, dann bauen um den Rest zu prüfen. Nach Task 6 wieder einkommentieren und gemeinsam committen.

---

### Task 6: `SteigSheet.swift` erstellen

**Files:**
- Create: `Linio/Content/SteigSheet.swift`

- [ ] **Schritt 1: Datei erstellen**

```swift
//  SteigSheet.swift
//  Linio

import SwiftUI
import MapKit

// MARK: - SteigSheet

struct SteigSheet: View {
    let departure: Departure
    let allDepartures: [Departure]
    let station: Station
    let graphQLService: GraphQLService
    let authService: AuthService

    @State private var quays: [StationQuay] = []
    @State private var isLoadingQuays = true
    @Environment(\.colorScheme) private var colorScheme
    private let formatter = DateFormattingHelper.shared

    // Alle Abfahrten vom gleichen Steig, aufsteigend sortiert
    private var departuresAtQuay: [Departure] {
        allDepartures
            .filter { $0.quayText == departure.quayText }
            .sorted {
                let fmt = DateFormattingHelper.shared
                let a = fmt.parseISO8601($0.scheduledDeparture) ?? .distantFuture
                let b = fmt.parseISO8601($1.scheduledDeparture) ?? .distantFuture
                return a < b
            }
    }

    // Alle Linienkürzel die an diesem Steig abfahren (dedupliziert, sortiert)
    private var linesAtQuay: [String] {
        Array(Set(departuresAtQuay.map { $0.lineName })).sorted()
    }

    // Buchstabe des gesuchten Steigs, z.B. "A" aus "Steig A"
    private var selectedLetter: String? {
        departure.quayText.flatMap {
            $0.split(separator: " ").last.map(String.init)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if !quays.isEmpty {
                    mapView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                departureList
            }
        }
        .background(AppTheme.canvasAdaptive(colorScheme))
        .task {
            guard let token = authService.accessToken else {
                isLoadingQuays = false
                return
            }
            quays = await graphQLService.getStationQuays(
                hafasID: station.hafasID,
                accessToken: token
            )
            isLoadingQuays = false
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(station.longName)
                .font(.caption)
                .foregroundColor(AppTheme.muted)
            Text(departure.quayText ?? "Unbekannter Steig")
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.inkAdaptive(colorScheme))
            if !linesAtQuay.isEmpty {
                Text("Linie " + linesAtQuay.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(AppTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: MapKit-Karte

    private var mapView: some View {
        Map(
            coordinateRegion: .constant(mapRegion),
            showsUserLocation: true,
            annotationItems: quays
        ) { quay in
            MapAnnotation(coordinate: quay.coordinate) {
                PlatformPin(
                    letter: quay.letter,
                    isHighlighted: quay.letter == selectedLetter
                )
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }

    // Region: umschließt alle Steige mit 20 % Padding
    private var mapRegion: MKCoordinateRegion {
        guard !quays.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.48, longitude: 8.47),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
        let lats = quays.map { $0.coordinate.latitude }
        let lons = quays.map { $0.coordinate.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.002),
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.002)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: Abfahrtsliste

    private var departureList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NÄCHSTE ABFAHRTEN")
                .font(.caption2.weight(.semibold))
                .foregroundColor(AppTheme.muted)
                .tracking(0.8)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            ForEach(Array(departuresAtQuay.enumerated()), id: \.element.id) { index, dep in
                HStack(spacing: 14) {
                    // Linien-Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(dep.lineColor)
                            .frame(width: 32, height: 32)
                        Text(dep.lineName)
                            .font(.caption.weight(.black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Text(dep.direction)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.inkAdaptive(colorScheme))
                        .lineLimit(1)
                    Spacer()
                    if let mins = dep.minutesUntilDeparture {
                        Text(mins == 0 ? "jetzt" : "\(mins) min")
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundColor(mins <= 1 ? AppTheme.semanticSuccess : AppTheme.inkAdaptive(colorScheme))
                    } else {
                        Text(formatter.formatTime(dep.scheduledDeparture))
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundColor(AppTheme.inkAdaptive(colorScheme))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if index < departuresAtQuay.count - 1 {
                    AppTheme.hairlineAdaptive(colorScheme)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

// MARK: - PlatformPin

private struct PlatformPin: View {
    let letter: String
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isHighlighted ? Color.orange : Color(red: 0.23, green: 0.23, blue: 0.42))
                .frame(width: isHighlighted ? 30 : 22, height: isHighlighted ? 30 : 22)
                .shadow(color: isHighlighted ? .orange.opacity(0.5) : .clear, radius: 6)
            Circle()
                .stroke(
                    isHighlighted ? Color.orange.opacity(0.4) : Color.blue.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: isHighlighted ? 30 : 22, height: isHighlighted ? 30 : 22)
            Text(letter)
                .font(.system(size: isHighlighted ? 13 : 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
```

- [ ] **Schritt 2: Datei zum Xcode-Projekt hinzufügen**

In Xcode: `Linio/Content`-Gruppe → Rechtsklick → „Add Files" → `SteigSheet.swift` auswählen (falls nicht automatisch erkannt).

- [ ] **Schritt 3: Bauen (⌘B) — muss fehlerfrei sein**

Häufige Fehler:
- `'AppTheme' has no member 'hairlineAdaptive'` → prüfen wie der Trennstrich in anderen Views heißt (z.B. `AppTheme.hairline`) und anpassen.
- `'AppTheme' has no member 'semanticSuccess'` → Namen in `AppTheme`-Definition nachschlagen und anpassen.
- `MapAnnotation` deprecated warning → OK, funktioniert.

- [ ] **Schritt 4: App starten und testen**

Manueller Test-Ablauf:
1. Station wählen (z.B. MA Hauptbahnhof)
2. Abfahrten laden — Steig-Badge (`Steig A`) muss rechts in Zeilen erscheinen wo `quayText` gesetzt ist
3. Badge antippen → Sheet öffnet
4. Sheet Header: Stationsname, Steig, Linienliste korrekt
5. Karte: falls `getStationQuays` Daten liefert, Pins sichtbar; gesuchter Steig orange
6. Abfahrtsliste: nur Abfahrten vom selben Steig
7. Kein Absturz wenn `quayText == nil` (Badge unsichtbar, kein Tap möglich)

- [ ] **Schritt 5: Commit**

```bash
git add Linio/Content/SteigSheet.swift Linio/Content/DepartureBoardView.swift
git commit -m "feat: SteigSheet mit MapKit-Karte und gefilterter Abfahrtsliste"
```

---

## Bekannte Unsicherheiten

**`station.stops { lat lon }` im API-Schema:** Die `getStationQuays`-Query könnte einen GraphQL-Fehler zurückgeben falls `stops` oder `lat`/`lon` nicht im Schema existieren. In diesem Fall gibt die Methode `[]` zurück und das Sheet zeigt nur die Abfahrtsliste (kein Absturz). Debug-Log prüfen: `getStationQuays: Keine Stop-Daten`.

**`stop.globalID` Steig-Kodierung:** Falls `globalID` im Journeys-Pfad kein Platform-Segment enthält (z.B. nur `de:08222:2505`), bleibt `quayText == nil` und Badges erscheinen nicht. Debug-Log in Task 2 gibt Aufschluss.

In beiden Fällen: Feature degradiert gracefully, kein Fehler für den Nutzer.
