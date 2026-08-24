// WatchAppIntents.swift
// Siri Shortcuts für die Apple Watch - "Hey Siri, wann fährt die nächste Bahn nach Heidelberg?"

import AppIntents
import Foundation

// MARK: - Nächste Abfahrt Intent

struct WatchNextDepartureIntent: AppIntent {
    static let title: LocalizedStringResource = "Nächste Abfahrt"
    static let description = IntentDescription("Zeigt die nächste Abfahrt zur gewählten Station.")
    
    @Parameter(title: "Ziel", description: "Wohin möchtest du fahren?")
    var destination: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Nächste Bahn nach \(\.$destination)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dataProvider = WatchIntentDataProvider()
        
        // Suche nach passender Fahrt
        if let dest = destination?.lowercased() {
            if let trip = dataProvider.findTripTo(destination: dest) {
                let depTime = WatchDateHelper.formatTime(trip.startTime)
                let mins = WatchDateHelper.minutesUntil(trip.startTime) ?? 0
                let minsText = mins == 0 ? "jetzt" : "in \(mins) Minuten"
                return .result(dialog: "Die nächste Bahn nach \(trip.endStation) fährt um \(depTime) Uhr, \(minsText).")
            } else {
                return .result(dialog: "Keine Fahrt nach \(destination ?? "diesem Ziel") gefunden. Bitte in der App eine Verbindung planen.")
            }
        }
        
        // Ohne Ziel: Zeige nächste aktive Fahrt
        if let trip = dataProvider.loadNextTrip() {
            let depTime = WatchDateHelper.formatTime(trip.startTime)
            let mins = WatchDateHelper.minutesUntil(trip.startTime) ?? 0
            return .result(dialog: "Deine nächste Fahrt nach \(trip.endStation) startet um \(depTime) Uhr, in \(mins) Minuten.")
        }
        
        return .result(dialog: "Keine aktive Fahrt gefunden. Plane eine Verbindung in der Linio App.")
    }
}

// MARK: - Abfahrten an Haltestelle Intent

struct WatchDeparturesAtStopIntent: AppIntent {
    static let title: LocalizedStringResource = "Abfahrten anzeigen"
    static let description = IntentDescription("Zeigt die nächsten Abfahrten an einer Haltestelle.")
    
    @Parameter(title: "Haltestelle", description: "Von welcher Haltestelle?")
    var stationName: String?
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let station = stationName ?? "Mannheim Hauptbahnhof"
        return .result(dialog: "Öffne die Watch-App für Abfahrten von \(station).")
    }
}

// MARK: - Fahrt Status Intent

struct WatchTripStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Fahrt Status"
    static let description = IntentDescription("Zeigt den Status deiner aktuellen Fahrt.")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let dataProvider = WatchIntentDataProvider()
        
        guard let trip = dataProvider.loadActiveTrip() else {
            return .result(dialog: "Du hast gerade keine aktive Fahrt.")
        }
        
        let phase = WatchDateHelper.phase(for: trip)
        let firstLeg = trip.legs.first(where: { $0.isTimedLeg })
        let lineName = WatchStyleHelper.shortName(firstLeg?.serviceName)
        
        switch phase {
        case .beforeDeparture:
            let mins = WatchDateHelper.minutesUntil(trip.startTime) ?? 0
            return .result(dialog: "Linie \(lineName) nach \(trip.endStation) fährt in \(mins) Minuten.")
        case .duringJourney:
            let mins = WatchDateHelper.minutesUntil(trip.endTime) ?? 0
            return .result(dialog: "Du bist unterwegs nach \(trip.endStation). Ankunft in etwa \(mins) Minuten.")
        case .arrived:
            return .result(dialog: "Du bist an \(trip.endStation) angekommen.")
        }
    }
}

// MARK: - App Shortcuts Provider für Watch

struct WatchAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WatchNextDepartureIntent(),
            phrases: [
                "Wann fährt die nächste Bahn in \(.applicationName)",
                "Nächste Abfahrt in \(.applicationName)"
            ],
            shortTitle: "Nächste Bahn",
            systemImageName: "tram.fill"
        )
        
        AppShortcut(
            intent: WatchTripStatusIntent(),
            phrases: [
                "Fahrt Status in \(.applicationName)",
                "Wo bin ich in \(.applicationName)",
                "Wann komme ich an in \(.applicationName)"
            ],
            shortTitle: "Fahrt Status",
            systemImageName: "location.fill"
        )
        
        AppShortcut(
            intent: WatchDeparturesAtStopIntent(),
            phrases: [
                "Abfahrten in \(.applicationName)",
                "Was fährt jetzt in \(.applicationName)"
            ],
            shortTitle: "Abfahrten",
            systemImageName: "clock.fill"
        )
    }
}

// MARK: - Watch Intent Data Provider

struct WatchIntentDataProvider {
    private let appGroupID = "group.com.stefanfriedrich.rnvapp"
    
    func loadActiveTrip() -> WidgetTripData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "savedTripData") else { return nil }
        
        let activeIDs = Set(defaults.stringArray(forKey: "activeTrips") ?? [])
        guard !activeIDs.isEmpty else { return nil }
        
        let now = Date()
        let allTrips = (try? JSONDecoder().decode([WidgetTripData].self, from: data)) ?? []
        
        return allTrips
            .filter { activeIDs.contains($0.id) }
            .filter { trip in
                guard let end = WatchDateHelper.parse(trip.endTime) else { return false }
                return end > now
            }
            .sorted {
                let a = WatchDateHelper.parse($0.startTime) ?? .distantFuture
                let b = WatchDateHelper.parse($1.startTime) ?? .distantFuture
                return a < b
            }
            .first
    }
    
    func loadNextTrip() -> WidgetTripData? {
        return loadActiveTrip()
    }
    
    func loadSavedTrips() -> [TripData] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "plannedTripData") else { return [] }
        return (try? JSONDecoder().decode([TripData].self, from: data)) ?? []
    }
    
    func findTripTo(destination: String) -> WidgetTripData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "savedTripData") else { return nil }
        
        let now = Date()
        let allTrips = (try? JSONDecoder().decode([WidgetTripData].self, from: data)) ?? []
        let destLower = destination.lowercased()
        
        // Suche in Heidelberg, Mannheim, Ludwigshafen etc.
        let keywords = ["heidelberg": "HD", "mannheim": "MA", "ludwigshafen": "LU",
                       "hd": "HD", "ma": "MA", "lu": "LU"]
        
        return allTrips
            .filter { trip in
                guard let end = WatchDateHelper.parse(trip.endTime), end > now else { return false }
                let endLower = trip.endStation.lowercased()
                
                // Direkter Match
                if endLower.contains(destLower) { return true }
                
                // Keyword Match
                for (key, abbrev) in keywords {
                    if destLower.contains(key) && (endLower.contains(key) || endLower.contains(abbrev.lowercased())) {
                        return true
                    }
                }
                return false
            }
            .sorted {
                let a = WatchDateHelper.parse($0.startTime) ?? .distantFuture
                let b = WatchDateHelper.parse($1.startTime) ?? .distantFuture
                return a < b
            }
            .first
    }
}
