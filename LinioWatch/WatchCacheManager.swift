// WatchCacheManager.swift
// Intelligentes Caching-System für die Watch App

import Foundation

/// Cache-Eintrag mit TTL (Time-To-Live)
struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let ttlSeconds: TimeInterval
    
    var isExpired: Bool { Date().timeIntervalSince(timestamp) > ttlSeconds }
    var ageSeconds: TimeInterval { Date().timeIntervalSince(timestamp) }
}

/// Zentrale Cache-Verwaltung für die Watch App
@MainActor
final class WatchCacheManager: ObservableObject {
    static let shared = WatchCacheManager()
    
    private enum CacheKey: String {
        case departures, connections, favoriteStations, lastSelectedStations, offlineDepartures
    }
    
    private struct TTL {
        static let departures: TimeInterval = 60        // 1 Minute
        static let connections: TimeInterval = 120      // 2 Minuten
        static let offlineData: TimeInterval = 3600     // 1 Stunde
    }
    
    @Published var favoriteStations: [WatchStation] = []
    @Published var lastStationID: String?
    @Published var lastStationName: String?
    @Published var cacheStats = CacheStats()
    
    struct CacheStats {
        var hitCount = 0
        var missCount = 0
        var savedAPICallsCount = 0
        var hitRate: Double {
            let total = hitCount + missCount
            return total > 0 ? Double(hitCount) / Double(total) : 0
        }
    }
    
    private let defaults = UserDefaults.standard
    private init() { loadFavorites(); loadLastSelectedStation() }
    
    // MARK: - Departures Cache
    
    func cacheDepartures(_ departures: [WatchDeparture], forStation stationID: String) {
        let entry = CacheEntry(data: departures, timestamp: Date(), ttlSeconds: TTL.departures)
        save(entry, forKey: "\(CacheKey.departures.rawValue)_\(stationID)")
        let offline = CacheEntry(data: departures, timestamp: Date(), ttlSeconds: TTL.offlineData)
        save(offline, forKey: "\(CacheKey.offlineDepartures.rawValue)_\(stationID)")
    }
    
    func getCachedDepartures(forStation stationID: String) -> [WatchDeparture]? {
        if let e: CacheEntry<[WatchDeparture]> = load(forKey: "\(CacheKey.departures.rawValue)_\(stationID)"),
           !e.isExpired { cacheStats.hitCount += 1; cacheStats.savedAPICallsCount += 1; return e.data }
        cacheStats.missCount += 1
        return nil
    }
    
    func getOfflineDepartures(forStation stationID: String) -> [WatchDeparture]? {
        guard let entry: CacheEntry<[WatchDeparture]> = load(forKey: "\(CacheKey.offlineDepartures.rawValue)_\(stationID)"),
              !entry.isExpired else { return nil }
        return entry.data
    }
    
    // MARK: - Connections Cache
    
    func cacheConnections(_ connections: [TripData], from: String, to: String) {
        let entry = CacheEntry(data: connections, timestamp: Date(), ttlSeconds: TTL.connections)
        save(entry, forKey: "\(CacheKey.connections.rawValue)_\(from)_\(to)")
    }
    
    func getCachedConnections(from: String, to: String) -> [TripData]? {
        if let e: CacheEntry<[TripData]> = load(forKey: "\(CacheKey.connections.rawValue)_\(from)_\(to)"),
           !e.isExpired { cacheStats.hitCount += 1; return e.data }
        cacheStats.missCount += 1
        return nil
    }
    
    // MARK: - Favorite Stations
    
    func addFavorite(_ station: WatchStation) {
        guard !favoriteStations.contains(where: { $0.id == station.id }) else { return }
        favoriteStations.insert(station, at: 0)
        if favoriteStations.count > 5 { favoriteStations.removeLast() }
        saveFavorites()
    }
    
    func removeFavorite(_ station: WatchStation) {
        favoriteStations.removeAll { $0.id == station.id }
        saveFavorites()
    }
    
    func isFavorite(_ stationID: String) -> Bool { favoriteStations.contains { $0.id == stationID } }
    func toggleFavorite(_ station: WatchStation) { isFavorite(station.id) ? removeFavorite(station) : addFavorite(station) }
    
    private func loadFavorites() {
        if let data = defaults.data(forKey: CacheKey.favoriteStations.rawValue),
           let s = try? JSONDecoder().decode([WatchStation].self, from: data) { favoriteStations = s }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteStations) { defaults.set(data, forKey: CacheKey.favoriteStations.rawValue) }
    }
    
    // MARK: - Last Selected Station
    
    func saveLastSelectedStation(id: String, name: String) {
        lastStationID = id; lastStationName = name
        defaults.set(id, forKey: "\(CacheKey.lastSelectedStations.rawValue)_id")
        defaults.set(name, forKey: "\(CacheKey.lastSelectedStations.rawValue)_name")
    }
    
    private func loadLastSelectedStation() {
        lastStationID = defaults.string(forKey: "\(CacheKey.lastSelectedStations.rawValue)_id")
        lastStationName = defaults.string(forKey: "\(CacheKey.lastSelectedStations.rawValue)_name")
    }
    
    // MARK: - Cache Cleanup
    
    func clearAllCaches() {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(CacheKey.departures.rawValue) || $0.hasPrefix(CacheKey.connections.rawValue) }
            .forEach { defaults.removeObject(forKey: $0) }
        cacheStats = CacheStats()
    }
    
    // MARK: - Generic Helpers
    
    private func save<T: Codable>(_ entry: CacheEntry<T>, forKey key: String) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        defaults.set(data, forKey: key)
    }
    
    private func load<T: Codable>(forKey key: String) -> CacheEntry<T>? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CacheEntry<T>.self, from: data)
    }
}

