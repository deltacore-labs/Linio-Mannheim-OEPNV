//
//  FavoriteStationsManager.swift
//  Linio
//
//  Verwaltet Favoriten-Haltestellen (Wohnung, Arbeit, Uni, etc.)
//

import Foundation
import SwiftUI
import Combine

// MARK: - FavoriteStation Model

struct FavoriteStation: Identifiable, Codable, Equatable {
    let id: UUID
    let station: Station
    var label: FavoriteLabel
    var customLabel: String?
    let createdAt: Date
    
    init(station: Station, label: FavoriteLabel, customLabel: String? = nil) {
        self.id = UUID()
        self.station = station
        self.label = label
        self.customLabel = customLabel
        self.createdAt = Date()
    }
    
    var displayLabel: String {
        if let custom = customLabel, !custom.isEmpty { return custom }
        return label.displayName
    }
    
    var icon: String {
        if let custom = customLabel, !custom.isEmpty { return "star.fill" }
        return label.icon
    }
    
    var iconColor: Color { label.color }
}

// MARK: - FavoriteLabel Enum

enum FavoriteLabel: String, Codable, CaseIterable, Identifiable {
    case home = "home"
    case work = "work"
    case university = "university"
    case gym = "gym"
    case family = "family"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .home: return "Zuhause"
        case .work: return "Arbeit"
        case .university: return "Uni"
        case .gym: return "Fitness"
        case .family: return "Familie"
        case .custom: return "Favorit"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .university: return "graduationcap.fill"
        case .gym: return "figure.run"
        case .family: return "heart.fill"
        case .custom: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .home: return .blue
        case .work: return .orange
        case .university: return .purple
        case .gym: return .green
        case .family: return .pink
        case .custom: return .yellow
        }
    }
}

// MARK: - FavoriteStationsManager

@MainActor
class FavoriteStationsManager: ObservableObject {
    static let shared = FavoriteStationsManager()
    
    @Published private(set) var favorites: [FavoriteStation] = []
    
    private let userDefaultsKey = "favoriteStations"
    private let maxFavorites = 6
    
    private init() { loadFavorites() }
    
    // MARK: - CRUD Operations
    
    func addFavorite(station: Station, label: FavoriteLabel, customLabel: String? = nil) -> Bool {
        guard !isFavorite(station: station) else { return false }
        guard favorites.count < maxFavorites else { return false }
        
        let favorite = FavoriteStation(station: station, label: label, customLabel: customLabel)
        favorites.append(favorite)
        saveFavorites()
        return true
    }
    
    func removeFavorite(station: Station) {
        favorites.removeAll { $0.station.globalID == station.globalID }
        saveFavorites()
    }
    
    func removeFavorite(id: UUID) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }
    
    func updateFavorite(id: UUID, label: FavoriteLabel, customLabel: String?) {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else { return }
        favorites[index].label = label
        favorites[index].customLabel = customLabel
        saveFavorites()
    }
    
    func isFavorite(station: Station) -> Bool {
        favorites.contains { $0.station.globalID == station.globalID }
    }
    
    func getFavorite(for station: Station) -> FavoriteStation? {
        favorites.first { $0.station.globalID == station.globalID }
    }
    
    func reorderFavorites(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        saveFavorites()
    }
    
    var canAddMore: Bool { favorites.count < maxFavorites }
    var remainingSlots: Int { maxFavorites - favorites.count }
    
    // MARK: - Persistence
    
    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favorites)
            if let groupDefaults = UserDefaults(suiteName: AppConfiguration.appGroupID) {
                groupDefaults.set(data, forKey: AppConfiguration.UserDefaultsKey.widgetFavoriteStations.rawValue)
            }
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            plog("FavoriteStationsManager: Fehler beim Speichern der Favoriten: \(error)")
        }
    }
    
    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([FavoriteStation].self, from: data) else {
            favorites = []
            return
        }
        favorites = decoded
    }
    
    func clearAll() {
        favorites = []
        saveFavorites()
    }
}
