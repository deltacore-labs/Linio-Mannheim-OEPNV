// WidgetIntents.swift
// Linio
//
// Definiert StationEntity und StationSelectionIntent auch im Haupt-App-Target,
// damit iOS den Intent bei Widget-Konfiguration im App-Prozess auflösen kann.

import AppIntents
import WidgetKit


struct StationEntity: AppEntity, Codable {
    let globalID: String
    let longName: String
    let hafasID: String

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

struct StationSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Station wählen"
    static var description = IntentDescription(LocalizedStringResource("Wähle eine Haltestelle für die Abfahrtstafel."))

    @Parameter(title: LocalizedStringResource("Haltestelle"))
    var station: StationEntity?
}

// Registers StationEntity + StationSelectionIntent in the main app's AppIntents metadata,
// which is required for widget intent resolution in the host app process.
struct LinioWidgetIntentsPackage: AppIntentsPackage {}
