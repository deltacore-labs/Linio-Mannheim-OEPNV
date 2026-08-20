//
//  AppIntents.swift
//  Linio
//

import AppIntents
import SwiftUI

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
