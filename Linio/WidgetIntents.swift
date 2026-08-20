// WidgetIntents.swift
// Linio
//
// Definiert StationEntity und StationSelectionIntent auch im Haupt-App-Target,
// damit iOS den Intent bei Widget-Konfiguration im App-Prozess auflösen kann.

import AppIntents
import WidgetKit
import ActivityKit


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

// MARK: - Interactive Widget: Live Activity aus Widget starten

struct StartNextTripLiveActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Live-Verfolgung starten"
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        guard let trip = WidgetDataProvider.loadNextTrip() else { return .result() }

        let running = Activity<TripLiveActivityAttributes>.activities
        guard !running.contains(where: { $0.attributes.tripId == trip.id }) else { return .result() }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return .result() }

        guard let firstLeg = trip.legs.first(where: { $0.isTimedLeg }),
              let serviceName = firstLeg.serviceName,
              let serviceType = firstLeg.serviceType,
              let destination = firstLeg.destinationLabel,
              let boardStop = firstLeg.boardStopName else { return .result() }

        let attrs = TripLiveActivityAttributes(
            tripId: trip.id,
            startStation: trip.startStation,
            endStation: trip.endStation,
            totalLegs: trip.legs.filter { $0.isTimedLeg }.count,
            departureTimeISO: trip.startTime,
            arrivalTimeISO: trip.endTime
        )

        let now = Date()
        let depDate = WidgetDataProvider.parseISO8601(trip.startTime)
        let phase: TripPhase = (depDate.map { $0 > now }) == true ? .beforeDeparture : .duringJourney
        let depTimeStr = WidgetDataProvider.formatTime(firstLeg.departureTime ?? trip.startTime)

        let state = TripLiveActivityAttributes.ContentState(
            currentLegIndex: 0,
            nextStopName: boardStop,
            nextStopTime: depTimeStr,
            estimatedTime: nil,
            delay: nil,
            destination: destination,
            lineName: serviceName,
            serviceType: serviceType,
            phase: phase
        )

        try? Activity.request(attributes: attrs, content: .init(state: state, staleDate: nil))
        return .result()
    }
}
