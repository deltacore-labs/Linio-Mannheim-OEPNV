//
//  GraphQLService.swift
//  Linio
//

import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

// MARK: - Data Models

struct Station: Identifiable, Codable, Equatable {
    let hafasID: String
    let globalID: String
    let longName: String
    let latitude: Double?
    let longitude: Double?
    var id: String { globalID }
}

enum LegType: String, Codable {
    case timedLeg = "TimedLeg"
    case continuousLeg = "ContinuousLeg"
    case interchangeLeg = "InterchangeLeg"
}

enum OccupancyLevel: String, Codable, CaseIterable {
    case unknown = "UNKNOWN"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"

    init(from apiValue: String) {
        switch apiValue.trimmingCharacters(in: .whitespaces) {
        case "I":   self = .low
        case "II":  self = .medium
        case "III": self = .high
        default:
            let normalized = apiValue.uppercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
            self = OccupancyLevel(rawValue: normalized) ?? .unknown
        }
    }

    var displayText: String {
        switch self {
        case .unknown: return "Keine Daten"
        case .low:     return "Gering"
        case .medium:  return "Mittel"
        case .high:    return "Hoch"
        }
    }

    var iconName: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .low:     return "person"
        case .medium:  return "person.2"
        case .high:    return "person.3"
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .low:     return .green
        case .medium:  return .orange
        case .high:    return .red
        }
    }

    var filledCount: Int {
        switch self {
        case .unknown: return 0
        case .low:     return 1
        case .medium:  return 2
        case .high:    return 3
        }
    }

    var severityRank: Int {
        switch self {
        case .unknown: return 0
        case .low:     return 1
        case .medium:  return 2
        case .high:    return 3
        }
    }
}

struct StationQuay: Identifiable {
    let id: String
    let name: String
    let letter: String
    let coordinate: CLLocationCoordinate2D

    static func quayText(fromRef ref: String) -> String? {
        let parts = ref.split(separator: ":")
        guard parts.count >= 5 else { return nil }
        let segment = String(parts[4])
        guard !segment.isEmpty, segment != "0", segment != "null" else { return nil }
        guard segment.range(of: #"^[A-Z]{1,2}[0-9]?$|^[0-9]{1,3}$"#, options: .regularExpression) != nil else { return nil }
        return "Steig \(segment)"
    }

    static func letter(fromName name: String) -> String {
        String(name.split(separator: " ").last ?? Substring(name.prefix(1)))
    }

    static func boundingRegion(for quays: [StationQuay]) -> MKCoordinateRegion {
        let lats = quays.map { $0.coordinate.latitude }
        let lons = quays.map { $0.coordinate.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.48, longitude: 8.47),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.0012),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.0012)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}


struct DetailedTrip: Identifiable, Equatable {
    let id: UUID
    let startTime: String
    let endTime: String
    let interchanges: Int
    let legs: [TripLeg]

    init(startTime: String, endTime: String, interchanges: Int, legs: [TripLeg]) {
        self.startTime = startTime
        self.endTime = endTime
        self.interchanges = interchanges
        self.legs = legs
        self.id = Self.generateStableID(startTime: startTime, endTime: endTime, legs: legs)
    }

    /// Erzeugt eine deterministische UUID basierend auf Trip-Inhalt.
    /// So bekommt derselbe Trip bei jedem API-Abruf die gleiche ID –
    /// entscheidend für korrekte Live-Activity-Zuordnung.
    private static func generateStableID(startTime: String, endTime: String, legs: [TripLeg]) -> UUID {
        let firstTimedLeg = legs.first(where: { $0.type == .timedLeg })
        let lastTimedLeg = legs.last(where: { $0.type == .timedLeg })
        let stableString = [
            startTime,
            endTime,
            firstTimedLeg?.departureTime ?? "",
            firstTimedLeg?.serviceName ?? "",
            firstTimedLeg?.boardStopName ?? "",
            lastTimedLeg?.alightStopName ?? ""
        ].joined(separator: "|")

        // Deterministischer Hash → UUID (djb2-Variante, 2×64 Bit)
        var h1: UInt64 = 5381
        var h2: UInt64 = 5381
        for (i, byte) in stableString.utf8.enumerated() {
            if i % 2 == 0 {
                h1 = ((h1 &<< 5) &+ h1) &+ UInt64(byte)
            } else {
                h2 = ((h2 &<< 5) &+ h2) &+ UInt64(byte)
            }
        }

        var bytes = [UInt8](repeating: 0, count: 16)
        withUnsafeBytes(of: h1.bigEndian) { buf in
            for i in 0..<8 { bytes[i] = buf[i] }
        }
        withUnsafeBytes(of: h2.bigEndian) { buf in
            for i in 0..<8 { bytes[i + 8] = buf[i] }
        }
        // UUID Version-5- und Variant-Bits setzen
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                           bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11],
                           bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

struct IntermediateStop: Equatable {
    let name: String
    let scheduledTime: String?
    let estimatedTime: String?
    let occupancy: OccupancyLevel?
    let latitude: Double?
    let longitude: Double?
}

struct TripLeg: Identifiable, Equatable {
    let id = UUID()

    // Performance: Equatable-Vergleich ignoriert id (da UUID bei jedem Init neu)
    static func == (lhs: TripLeg, rhs: TripLeg) -> Bool {
        lhs.type == rhs.type &&
        lhs.boardStopName == rhs.boardStopName &&
        lhs.alightStopName == rhs.alightStopName &&
        lhs.departureTime == rhs.departureTime &&
        lhs.arrivalTime == rhs.arrivalTime &&
        lhs.estimatedDepartureTime == rhs.estimatedDepartureTime &&
        lhs.estimatedArrivalTime == rhs.estimatedArrivalTime &&
        lhs.serviceName == rhs.serviceName &&
        lhs.occupancy == rhs.occupancy
    }
    let type: LegType
    let mode: String?

    let boardStopName: String?
    let alightStopName: String?
    let departureTime: String?
    let arrivalTime: String?
    let estimatedDepartureTime: String?
    let estimatedArrivalTime: String?

    let serviceType: String?
    let serviceName: String?
    let serviceDescription: String?
    let destinationLabel: String?
    var intermediateStops: [IntermediateStop] = []

    /// Auslastung/Kapazität für diesen Leg
    var occupancy: OccupancyLevel?

    /// StopPoint-Referenz des Einstiegs (z.B. "de:08222:2417:1:1") – für nachträgliches Occupancy-Enrichment
    var boardRef: String? = nil

    /// API coordinates for the board stop (avoids geocoding)
    let boardLatitude: Double?
    let boardLongitude: Double?
    /// API coordinates for the alight stop (avoids geocoding)
    let alightLatitude: Double?
    let alightLongitude: Double?

    /// Convenience: is this a timed (vehicle) leg?
    var isTimedLeg: Bool { type == .timedLeg }

    // Initializer mit occupancy (Standard: nil)
    init(
        type: LegType,
        mode: String?,
        boardStopName: String?,
        alightStopName: String?,
        departureTime: String?,
        arrivalTime: String?,
        estimatedDepartureTime: String?,
        estimatedArrivalTime: String?,
        serviceType: String?,
        serviceName: String?,
        serviceDescription: String?,
        destinationLabel: String?,
        intermediateStops: [IntermediateStop] = [],
        occupancy: OccupancyLevel? = nil,
        boardRef: String? = nil,
        boardLatitude: Double? = nil,
        boardLongitude: Double? = nil,
        alightLatitude: Double? = nil,
        alightLongitude: Double? = nil
    ) {
        self.type = type
        self.mode = mode
        self.boardStopName = boardStopName
        self.alightStopName = alightStopName
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.estimatedDepartureTime = estimatedDepartureTime
        self.estimatedArrivalTime = estimatedArrivalTime
        self.serviceType = serviceType
        self.serviceName = serviceName
        self.serviceDescription = serviceDescription
        self.destinationLabel = destinationLabel
        self.intermediateStops = intermediateStops
        self.occupancy = occupancy
        self.boardRef = boardRef
        self.boardLatitude = boardLatitude
        self.boardLongitude = boardLongitude
        self.alightLatitude = alightLatitude
        self.alightLongitude = alightLongitude
    }
}

// MARK: - GraphQL Error

struct GraphQLError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Connection Loading Mode

enum ConnectionLoadingMode {
    case replace
    case prepend
    case append
}

// MARK: - GraphQL Service

@MainActor
class GraphQLService: ObservableObject {
    static let shared = GraphQLService()

    @Published var stations: [Station] = []
    @Published var detailedTrips: [DetailedTrip] = []
    @Published var isLoading = false
    @Published var lastError: NetworkError?

    internal var baseURL: String

    // MARK: - Departures Result + Hub Cache

    struct DeparturesResult {
        let departures: [Departure]
        let error: NetworkError?
    }

    static var cachedHubIDs: [String] = []
    static var cachedHubIDsDate: Date?
    static let hubIDsCacheTTL: TimeInterval = 86400 // 24h

    init() {
        self.baseURL = Self.loadGraphQLURL()
#if DEBUG
        print("📡 [GraphQL] Service initialisiert mit URL: \(self.baseURL)")
#endif
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfiguration.requestTimeout
        config.timeoutIntervalForResource = AppConfiguration.resourceTimeout
        
        // Performance: URL-Cache für häufig wiederholte Anfragen
        // Reduziert Netzwerkverkehr und verbessert Antwortzeiten
        config.urlCache = URLCache(
            memoryCapacity: 10_000_000,  // 10 MB In-Memory Cache
            diskCapacity: 50_000_000,    // 50 MB Disk Cache
            diskPath: "graphql_cache"
        )
        // Nutze Cache falls verfügbar, sonst Netzwerk
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        return URLSession(configuration: config)
    }()

    private static func loadGraphQLURL() -> String {
        let fallbackURL = AppConfiguration.fallbackGraphQLURL

        guard let bundleURL = Bundle.main.object(forInfoDictionaryKey: "RNV_GRAPHQL_URL") as? String else {
#if DEBUG
            print("⚠️ [GraphQL] RNV_GRAPHQL_URL nicht in Info.plist gefunden")
#endif
            return fallbackURL
        }

        // Anführungszeichen entfernen, falls xcconfig-Wert mit Quotes gespeichert ist (z.B. "https://...")
        let trimmedURL = bundleURL.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

        guard !trimmedURL.contains("$(") else {
#if DEBUG
            print("❌ [GraphQL] Variable nicht aufgelöst: \(trimmedURL)")
#endif
            return fallbackURL
        }

        guard !trimmedURL.isEmpty, URL(string: trimmedURL) != nil else {
#if DEBUG
            print("❌ [GraphQL] Ungültige URL: \(trimmedURL)")
#endif
            return fallbackURL
        }

#if DEBUG
        print("✅ [GraphQL] URL erfolgreich geladen: \(trimmedURL)")
#endif
        return trimmedURL
    }

    // MARK: - Input Sanitization

    /// Sanitizes user input to prevent GraphQL injection.
    func sanitize(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\0", with: "")
            .replacingOccurrences(of: "\t", with: " ")
    }

    // MARK: - GraphQL Response Parsing

    /// Parst die GraphQL Response-Daten. Diese Funktion ist `nonisolated`, da sie
    /// reine Datenverarbeitung macht ohne State zu verändern.
    nonisolated func parseResponseData(from data: Data) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["data"] as? [String: Any]
    }

    /// Extrahiert GraphQL-Fehler aus der Response. Diese Funktion ist `nonisolated`, da sie
    /// reine Datenverarbeitung macht ohne State zu verändern.
    nonisolated func extractGraphQLErrors(from data: Data) -> NetworkError? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msg = (json["errors"] as? [[String: Any]])?.first?["message"] as? String
        else { return nil }
        return .graphQLError(message: msg)
    }

    // MARK: - Query Execution

    /// Executes a GraphQL query and returns the raw response data.
    internal func executeQuery(query: String, accessToken: String, retryCount: Int = 0) async throws -> Data {
        guard let url = URL(string: baseURL) else {
            throw NetworkError.serverUnreachable
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["query": query]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            throw NetworkError.invalidResponse
        }
        request.httpBody = bodyData

#if DEBUG
        print("📡 [GraphQL] Anfrage an: \(url.host ?? "")")
#endif

        let (data, response) = try await Self.session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
#if DEBUG
            print("📡 [GraphQL] Response Status: \(httpResponse.statusCode)")
#endif
            guard (200...299).contains(httpResponse.statusCode) else {
                let body = String(data: data.prefix(500), encoding: .utf8) ?? "?"
                plog("executeQuery: HTTP \(httpResponse.statusCode) – \(body)")
#if DEBUG
                print("❌ [GraphQL] Error body (\(httpResponse.statusCode)): \(body)")
#endif
                if httpResponse.statusCode == 401 {
                    guard retryCount < 1 else {
                        throw NetworkError.unauthorized
                    }
                    plog("executeQuery: HTTP 401 – Token erneuern und erneut versuchen")
                    await AuthService.shared.autoAuthenticate()
                    guard AuthService.shared.isAuthenticated,
                          let newToken = AuthService.shared.accessToken else {
                        throw NetworkError.unauthorized
                    }
                    return try await executeQuery(query: query, accessToken: newToken, retryCount: retryCount + 1)
                }
                throw NetworkError.from(httpStatusCode: httpResponse.statusCode) ?? .httpError(code: httpResponse.statusCode)
            }
        }

#if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 [GraphQL] Response: \(jsonString.prefix(200))...")
        }
#endif

        return data
    }
}
