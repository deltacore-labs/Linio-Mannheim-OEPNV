//
//  ServiceAlertsManager.swift
//  Linio
//
//  Verwaltet Störungsmeldungen und Service-Alerts für Linien und Haltestellen
//

import Foundation
import SwiftUI
import Combine

// MARK: - ServiceAlert Model

struct ServiceAlert: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let severity: AlertSeverity
    let validFrom: Date
    let validUntil: Date?
    let affectedLines: [String]
    let affectedStations: [String]
    let category: AlertCategory
    let source: String
    
    var isActive: Bool {
        let now = Date()
        if now < validFrom { return false }
        if let until = validUntil, now > until { return false }
        return true
    }
    
    var formattedValidityPeriod: String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        df.locale = Locale(identifier: "de_DE")
        let from = df.string(from: validFrom)
        if let until = validUntil {
            return "\(from) – \(df.string(from: until))"
        }
        return "Ab \(from)"
    }
}

// MARK: - AlertSeverity Enum

enum AlertSeverity: String, Codable, CaseIterable {
    case info = "INFO"
    case warning = "WARNING"
    case severe = "SEVERE"
    
    var displayName: String {
        switch self {
        case .info: return "Information"
        case .warning: return "Einschränkung"
        case .severe: return "Störung"
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .severe: return "xmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .severe: return .red
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .severe: return 0
        case .warning: return 1
        case .info: return 2
        }
    }
}

// MARK: - AlertCategory Enum

enum AlertCategory: String, Codable, CaseIterable {
    case disruption = "DISRUPTION"
    case construction = "CONSTRUCTION"
    case detour = "DETOUR"
    case delay = "DELAY"
    case replacement = "REPLACEMENT"
    case event = "EVENT"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .disruption: return "Störung"
        case .construction: return "Baustelle"
        case .detour: return "Umleitung"
        case .delay: return "Verspätung"
        case .replacement: return "Ersatzverkehr"
        case .event: return "Veranstaltung"
        case .other: return "Sonstiges"
        }
    }
    
    var icon: String {
        switch self {
        case .disruption: return "bolt.slash.fill"
        case .construction: return "hammer.fill"
        case .detour: return "arrow.triangle.swap"
        case .delay: return "clock.badge.exclamationmark"
        case .replacement: return "bus.fill"
        case .event: return "star.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - ServiceAlertsManager

@MainActor
class ServiceAlertsManager: ObservableObject {
    static let shared = ServiceAlertsManager()
    
    @Published var alerts: [ServiceAlert] = []
    @Published var isLoading = false
    @Published var lastUpdate: Date?
    @Published var error: String?
    
    private let cacheKey = "cachedServiceAlerts"
    private let cacheTimestampKey = "serviceAlertsCacheTimestamp"
    private let cacheTTL: TimeInterval = 300
    
    private init() {
        loadCachedAlerts()
    }
    
    func fetchAlerts(accessToken: String, forceRefresh: Bool = false) async {
        if !forceRefresh, let lastCache = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date {
            if Date().timeIntervalSince(lastCache) < cacheTTL && !alerts.isEmpty { return }
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedAlerts = try await fetchAlertsFromAPI(accessToken: accessToken)
            alerts = fetchedAlerts.sorted { $0.severity.sortOrder < $1.severity.sortOrder }
            lastUpdate = Date()
            cacheAlerts()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func alerts(forLine lineName: String) -> [ServiceAlert] {
        alerts.filter { $0.isActive && $0.affectedLines.contains { $0.lowercased() == lineName.lowercased() } }
    }
    
    func alerts(forStation stationName: String) -> [ServiceAlert] {
        alerts.filter { $0.isActive && $0.affectedStations.contains { 
            $0.lowercased().contains(stationName.lowercased()) || stationName.lowercased().contains($0.lowercased())
        }}
    }
    
    var activeAlerts: [ServiceAlert] { alerts.filter { $0.isActive } }
    var severeAlertCount: Int { activeAlerts.filter { $0.severity == .severe }.count }
    
    // MARK: - API Integration
    
    private func fetchAlertsFromAPI(accessToken: String) async throws -> [ServiceAlert] {
        // Die RNV-API bietet möglicherweise ServiceAlerts über station.journeys
        // Falls nicht verfügbar, nutzen wir einen simulierten Fallback
        let hubStations = ["Mannheim Hauptbahnhof", "Heidelberg Hauptbahnhof"]
        var allAlerts: [ServiceAlert] = []
        
        for hubName in hubStations {
            if let alerts = try? await fetchAlertsForStation(stationName: hubName, accessToken: accessToken) {
                allAlerts.append(contentsOf: alerts)
            }
        }
        
        var seenIDs = Set<String>()
        return allAlerts.filter { seenIDs.insert($0.id).inserted }
    }
    
    private func fetchAlertsForStation(stationName: String, accessToken: String) async throws -> [ServiceAlert] {
        guard let url = URL(string: GraphQLService.shared.baseURL) else { return [] }
        
        let query = """
        { stations(first: 1, name: "\(stationName)") { elements { ... on Station { hafasID longName } } } }
        """
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": query])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return parseAlertsFromResponse(data)
    }
    
    private func parseAlertsFromResponse(_ data: Data) -> [ServiceAlert] {
        // Parse native serviceAlerts falls API sie unterstützt
        // Aktuell gibt die RNV-API keine ServiceAlerts zurück, daher leeres Array
        return []
    }
    
    // MARK: - Cache
    
    private func cacheAlerts() {
        if let encoded = try? JSONEncoder().encode(alerts) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        }
    }
    
    private func loadCachedAlerts() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([ServiceAlert].self, from: data) {
            alerts = decoded
            lastUpdate = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date
        }
    }
}
