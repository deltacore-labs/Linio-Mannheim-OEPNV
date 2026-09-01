//
//  StationDepartureWidget.swift
//  LinioLiveActivity
//
//  Konfigurierbares Abfahrtstafel-Widget für eine frei wählbare Haltestelle.
//

import WidgetKit
import SwiftUI
import AppIntents
import Security

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
// MARK: - Timeline Entry
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct StationDepartureEntry: TimelineEntry {
    let date: Date
    let configuration: StationSelectionIntent
    let stationName: String
    let departures: [WidgetDeparture]
    let errorState: StationWidgetError?
    let isPlaceholder: Bool
    var relevance: TimelineEntryRelevance? = nil
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Netzwerk-Service (schlanker GraphQL-Fetch für Widget)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

private struct WidgetDepartureService {

    enum FetchResult {
        case success([WidgetDeparture])
        case unauthorized
        case failed
    }

    /// Liefert `.unauthorized` bei 401, `.failed` bei sonstigen Fehlern, `.success` bei 2xx.
    static func fetch(hafasID: String, token: String, graphqlURL: String) async -> FetchResult {
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
                    pole { platform { label } }
                  }
                  allStops: stops {
                    station { longName }
                  }
                }
              }
            }
          }
        }
        """

        guard let url = URL(string: graphqlURL) else { return .failed }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        guard let body = try? JSONSerialization.data(withJSONObject: ["query": query]) else { return .failed }
        request.httpBody = body

        guard let (data, response) = try? await URLSession.shared.data(for: request) else { return .failed }

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 { return .unauthorized }
            guard (200...299).contains(http.statusCode) else { return .failed }
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let stationObj = responseData["station"] as? [String: Any],
              let journeysObj = stationObj["journeys"] as? [String: Any],
              let elements = journeysObj["elements"] as? [[String: Any]] else { return .failed }

        return .success(elements.compactMap { parse(element: $0, hafasID: safeID) })
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
        let destination = allStops.last.flatMap { ($0["station"] as? [String: Any])?["longName"] as? String } ?? ""

        let poleObj = firstStop["pole"] as? [String: Any]
        let platformLabel = (poleObj?["platform"] as? [String: Any])?["label"] as? String
        let quayText: String? = platformLabel.map { "Steig \($0)" }

        return WidgetDeparture(
            serviceName: lineName,
            serviceType: serviceType,
            destination: destination,
            plannedTimeISO: planned,
            realtimeTimeISO: realtime,
            quayText: quayText
        )
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
        let nextRefresh = Date().addingTimeInterval(10 * 60)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func buildEntry(for configuration: StationSelectionIntent) async -> StationDepartureEntry {
        let defaults = UserDefaults(suiteName: "group.com.stefanfriedrich.rnvapp")

        // Token aus Shared Keychain lesen
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.stefanfriedrich.rnvapp.widget",
            kSecAttrAccount as String: "widgetAccessToken",
            kSecAttrAccessGroup as String: "A4HCRKN53K.group.com.stefanfriedrich.rnvapp",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var keychainResult: AnyObject?
        SecItemCopyMatching(keychainQuery as CFDictionary, &keychainResult)
        let token = (keychainResult as? Data).flatMap { String(data: $0, encoding: .utf8) }

        guard let token, !token.isEmpty else {
            return StationDepartureEntry(
                date: Date(), configuration: configuration,
                stationName: "—", departures: [], errorState: .noToken, isPlaceholder: false
            )
        }

        let tokenExpiry = defaults?.double(forKey: "widgetAccessTokenExpiry") ?? 0
        guard tokenExpiry > Date().timeIntervalSince1970 + 60 else {
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

        let fetchResult = await WidgetDepartureService.fetch(
            hafasID: station.hafasID,
            token: token,
            graphqlURL: graphqlURL
        )

        switch fetchResult {
        case .unauthorized:
            return StationDepartureEntry(
                date: Date(), configuration: configuration,
                stationName: station.longName, departures: [], errorState: .noToken, isPlaceholder: false
            )
        case .failed:
            return StationDepartureEntry(
                date: Date(), configuration: configuration,
                stationName: station.longName, departures: [], errorState: .networkError, isPlaceholder: false
            )
        case .success(let departures):
            let relevance: TimelineEntryRelevance? = {
                guard let firstDep = departures.first,
                      let depDate = WidgetDataProvider.parseISO8601(firstDep.effectiveTimeISO) else { return nil }
                let mins = depDate.timeIntervalSince(Date()) / 60
                if mins < 5 { return TimelineEntryRelevance(score: 10.0, duration: 5 * 60) }
                if mins < 20 { return TimelineEntryRelevance(score: 5.0, duration: 5 * 60) }
                return TimelineEntryRelevance(score: 1.0, duration: 5 * 60)
            }()
            return StationDepartureEntry(
                date: Date(),
                configuration: configuration,
                stationName: station.longName,
                departures: departures,
                errorState: nil,
                isPlaceholder: false,
                relevance: relevance
            )
        }
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

            if let quay = dep.quayText {
                Text(quay)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

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
        let depDate = WidgetDataProvider.parseISO8601(dep.effectiveTimeISO)

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
                }
                Spacer()
                CountdownText(depDate: depDate, referenceDate: entry.date)
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
        if entry.isPlaceholder {
            placeholderMediumView
        } else if let error = entry.errorState {
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

    private var placeholderMediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(width: 100, height: 10)
            Divider()
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.2)).frame(width: 40, height: 22)
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.12)).frame(maxWidth: .infinity, minHeight: 10, maxHeight: 10)
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)).frame(width: 24, height: 10)
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
        if entry.isPlaceholder {
            placeholderLargeView
        } else if let error = entry.errorState {
            errorLargeView(error)
        } else {
            contentView
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
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

    private var placeholderLargeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.15)).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(width: 120, height: 11)
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)).frame(width: 60, height: 9)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            Divider()
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.2)).frame(width: 40, height: 22)
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.12)).frame(maxWidth: .infinity, minHeight: 10, maxHeight: 10)
                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.1)).frame(width: 24, height: 10)
                }
                .padding(.vertical, 6)
                Divider()
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Lock Screen Accessory Views (iOS 16+)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Inline Lock Screen Widget: "🚊 5 → Heidelberg · 3'"
struct StationAccessoryInlineView: View {
    let entry: StationDepartureEntry
    
    var body: some View {
        if let dep = entry.departures.first {
            let depDate = WidgetDataProvider.parseISO8601(dep.effectiveTimeISO)
            Label {
                if let d = depDate, d > entry.date {
                    Text("\(dep.serviceName) → \(shortDestination(dep.destination)) · ") +
                    Text(timerInterval: entry.date...d, countsDown: true)
                } else {
                    Text("\(dep.serviceName) → \(shortDestination(dep.destination)) · jetzt")
                }
            } icon: {
                Image(systemName: WidgetTheme.lineIcon(for: dep.serviceType, serviceName: dep.serviceName))
            }
        } else if entry.errorState == .noStation {
            Label("Station wählen", systemImage: "mappin.slash")
        } else {
            Label("Keine Abfahrten", systemImage: "tram.fill")
        }
    }

    private func shortDestination(_ dest: String) -> String {
        let short = dest.replacingOccurrences(of: " Hbf", with: "")
                        .replacingOccurrences(of: " Hauptbahnhof", with: "")
        return short.count > 12 ? String(short.prefix(10)) + "…" : short
    }
}

/// Circular Lock Screen Widget: Countdown im Kreis
struct StationAccessoryCircularView: View {
    let entry: StationDepartureEntry
    
    var body: some View {
        ZStack {
            if let dep = entry.departures.first {
                let depDate = WidgetDataProvider.parseISO8601(dep.effectiveTimeISO)
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Text(dep.serviceName)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.7)
                    CountdownText(depDate: depDate, referenceDate: entry.date)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            } else {
                AccessoryWidgetBackground()
                Image(systemName: entry.errorState == .noStation ? "mappin.slash" : "tram.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Rectangular Lock Screen Widget: Linie + Ziel + Zeit
struct StationAccessoryRectangularView: View {
    let entry: StationDepartureEntry
    
    var body: some View {
        if let dep = entry.departures.first {
            let depDate = WidgetDataProvider.parseISO8601(dep.effectiveTimeISO)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: WidgetTheme.lineIcon(for: dep.serviceType, serviceName: dep.serviceName))
                        .font(.system(size: 10, weight: .bold))
                    Text(dep.serviceName)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                    Spacer()
                    CountdownText(depDate: depDate, referenceDate: entry.date)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                }
                Text(entry.stationName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("→ " + dep.destination)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                Image(systemName: entry.errorState == .noStation ? "mappin.slash" : "tram.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text(entry.errorState == .noStation ? "Station wählen" : "Keine Abfahrten")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: Container

struct StationDepartureContainerView: View {
    @Environment(\.widgetFamily) var family
    let entry: StationDepartureEntry

    var body: some View {
        switch family {
        case .systemLarge:          StationDepartureLargeView(entry: entry)
        case .systemMedium:         StationDepartureMediumView(entry: entry)
        case .accessoryCircular:    StationAccessoryCircularView(entry: entry)
        case .accessoryRectangular: StationAccessoryRectangularView(entry: entry)
        case .accessoryInline:      StationAccessoryInlineView(entry: entry)
        default:                    StationDepartureSmallView(entry: entry)
        }
    }
}

private func errorIcon(_ error: StationWidgetError) -> String {
    switch error {
    case .noToken:      return "lock.fill"
    case .noStation:    return "mappin.slash"
    case .networkError: return "wifi.slash"
    }
}

private func errorText(_ error: StationWidgetError) -> String {
    switch error {
    case .noToken:      return "Bitte App öffnen\nund anmelden"
    case .noStation:    return "Station konfigurieren\n(Widget lange drücken)"
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
        .configurationDisplayName("widget.stationDeparture.name")
        .description("widget.stationDeparture.description")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
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
