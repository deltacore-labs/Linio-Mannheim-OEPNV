//
//  AppIntents.swift
//  Linio
//

import AppIntents
import SwiftUI

// MARK: - App-Target Widget Data Provider
// Benötigt für Siri-Intents die auf gespeicherte Fahrten zugreifen

struct AppWidgetDataProvider {
    static let appGroupID = "group.com.stefanfriedrich.rnvapp"

    static func loadActiveTrips() -> [String] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
        return defaults.stringArray(forKey: "activeTrips") ?? []
    }

    static func loadSavedTrips() -> [AppWidgetTripData] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "savedTripData") else { return [] }
        return (try? JSONDecoder().decode([AppWidgetTripData].self, from: data)) ?? []
    }

    static func loadNextTrip() -> AppWidgetTripData? {
        let now = Date()
        let trips = loadSavedTrips()
        let activeIds = Set(loadActiveTrips())
        return trips
            .filter { activeIds.contains($0.id) }
            .filter { trip in
                guard let endDate = parseISO8601(trip.endTime) else { return false }
                return endDate > now
            }
            .sorted { a, b in
                let dateA = parseISO8601(a.startTime) ?? .distantFuture
                let dateB = parseISO8601(b.startTime) ?? .distantFuture
                return dateA < dateB
            }
            .first
    }

    private static let isoFormatterWithFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFormatterWithout: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    static func parseISO8601(_ string: String) -> Date? {
        isoFormatterWithFrac.date(from: string) ?? isoFormatterWithout.date(from: string)
    }

    static func formatTime(_ isoString: String) -> String {
        guard let date = parseISO8601(isoString) else { return "--:--" }
        return timeFormatter.string(from: date)
    }
}

struct AppWidgetTripData: Codable, Identifiable {
    let id: String
    let startTime: String
    let endTime: String
    let interchanges: Int?
    let startStation: String
    let endStation: String
    let legs: [AppWidgetTripLeg]
}

struct AppWidgetTripLeg: Codable {
    let legType: String?
    let boardStopName: String?
    let alightStopName: String?
    let departureTime: String?
    let arrivalTime: String?
    let serviceName: String?
    let serviceType: String?
    let destinationLabel: String?
    var isTimedLeg: Bool { legType == "TimedLeg" }
}

// Alias für Kompatibilität mit bestehendem Code
typealias WidgetDataProvider = AppWidgetDataProvider

// MARK: - Search Connections Intent

struct SearchConnectionsIntent: AppIntent {
    static let title: LocalizedStringResource = "Verbindung suchen"
    static let description = IntentDescription("Öffnet die ÖPNV Mannheim App zur Verbindungssuche.")

    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Show Nearby Departures Intent

struct ShowNearbyDeparturesIntent: AppIntent {
    static let title: LocalizedStringResource = "Abfahrten in der Nähe"
    static let description = IntentDescription("Zeigt die nächsten Abfahrten von Haltestellen in deiner Nähe.")

    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Show Planned Trips Intent

struct ShowPlannedTripsIntent: AppIntent {
    static let title: LocalizedStringResource = "Geplante Fahrten anzeigen"
    static let description = IntentDescription("Zeigt aktive Live Activities und verfolgte Fahrten.")

    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showTicketFullscreen = Notification.Name("de.rnv.showTicketFullscreen")
}

struct ShowTicketIntent: AppIntent {
    static let title: LocalizedStringResource = "Ticket vorzeigen"
    static let description = IntentDescription("Zeigt dein Deutschlandticket sofort im Vollbild.")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "pendingShowTicketFullscreen")
        NotificationCenter.default.post(name: .showTicketFullscreen, object: nil)
        return .result()
    }
}

// MARK: - App Shortcuts Provider

struct RNVAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchConnectionsIntent(),
            phrases: [
                "Verbindung suchen in \(.applicationName)",
                "Öffne \(.applicationName)"
            ],
            shortTitle: "Verbindung suchen",
            systemImageName: "tram.fill"
        )
        AppShortcut(
            intent: ShowNearbyDeparturesIntent(),
            phrases: [
                "Abfahrten in \(.applicationName) anzeigen",
                "Was fährt jetzt in \(.applicationName)"
            ],
            shortTitle: "Abfahrten in der Nähe",
            systemImageName: "location.fill"
        )
        AppShortcut(
            intent: ShowPlannedTripsIntent(),
            phrases: [
                "Meine Fahrten in \(.applicationName)"
            ],
            shortTitle: "Geplante Fahrten",
            systemImageName: "bell.fill"
        )
        AppShortcut(
            intent: ShowTicketIntent(),
            phrases: [
                "Ticket vorzeigen mit \(.applicationName)",
                "Deutschlandticket mit \(.applicationName) zeigen"
            ],
            shortTitle: "Ticket vorzeigen",
            systemImageName: "qrcode"
        )
        AppShortcut(
            intent: NextDepartureForLineIntent(),
            phrases: [
                "Nächste Abfahrt in \(.applicationName)",
                "Wann fährt meine Linie in \(.applicationName)"
            ],
            shortTitle: "Nächste Abfahrt",
            systemImageName: "tram.fill"
        )
    }
}

// MARK: - Next Departure For Line Intent (Siri)

struct NextDepartureForLineIntent: AppIntent {
    static let title: LocalizedStringResource = "Nächste Abfahrt für Linie"
    static let description = IntentDescription("Zeigt die nächste Abfahrtszeit für eine bestimmte Linie.")

    static let openAppWhenRun: Bool = true

    @Parameter(title: "Linie", description: "Liniennummer, z.B. 5, 33 oder S1")
    var lineName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trips = WidgetDataProvider.loadSavedTrips()
        let activeIds = Set(WidgetDataProvider.loadActiveTrips())

        let query = lineName
            .replacingOccurrences(of: "er$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "te$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        let now = Date()
        let match = trips
            .filter { activeIds.contains($0.id) }
            .filter { (WidgetDataProvider.parseISO8601($0.endTime) ?? .distantPast) > now }
            .first { trip in
                trip.legs.contains { leg in
                    guard leg.isTimedLeg, let svc = leg.serviceName else { return false }
                    let name = svc
                        .replacingOccurrences(of: "RNV ", with: "")
                        .replacingOccurrences(of: "Linie ", with: "")
                        .uppercased()
                    return name == query || name.hasPrefix(query)
                }
            }

        if let trip = match {
            let depTime = WidgetDataProvider.formatTime(trip.startTime)
            let mins = WidgetDataProvider.parseISO8601(trip.startTime)
                .map { max(0, Int($0.timeIntervalSinceNow / 60)) } ?? 0
            let minsText = mins == 0 ? "jetzt" : "in \(mins) Minuten"
            return .result(dialog: "Linie \(lineName) fährt um \(depTime) Uhr \(minsText) nach \(trip.endStation).")
        } else {
            return .result(dialog: "Gerade keine aktive Fahrt mit Linie \(lineName) gefunden. Bitte in der App eine Verbindung starten.")
        }
    }
}
