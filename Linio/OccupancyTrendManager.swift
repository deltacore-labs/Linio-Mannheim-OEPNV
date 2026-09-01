//
//  OccupancyTrendManager.swift
//  Linio
//
//  Sammelt und analysiert historische Auslastungsdaten für Verbindungen
//

import Foundation
import SwiftUI
import Combine

// MARK: - OccupancyRecord

struct OccupancyRecord: Codable {
    let lineName: String
    let direction: String
    let stationName: String
    let dayOfWeek: Int      // 1 = Sonntag, 2 = Montag, ...
    let hourOfDay: Int      // 0-23
    let occupancy: OccupancyLevel
    let timestamp: Date
}

// MARK: - OccupancyTrend

struct OccupancyTrend {
    let lineName: String
    let direction: String
    let stationName: String
    let dayOfWeek: Int
    let hourOfDay: Int
    let averageOccupancy: OccupancyLevel
    let sampleCount: Int
    let confidence: TrendConfidence
    
    var dayName: String {
        let days = ["", "So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
        return days[min(max(dayOfWeek, 1), 7)]
    }
    
    var timeRange: String {
        String(format: "%02d:00–%02d:00", hourOfDay, (hourOfDay + 1) % 24)
    }
    
    var displayText: String { "\(dayName) \(timeRange): \(averageOccupancy.displayText)" }
}

enum TrendConfidence: String {
    case low, medium, high
    
    var displayText: String {
        switch self {
        case .low: return "Wenig Daten"
        case .medium: return "Basierend auf einigen Fahrten"
        case .high: return "Zuverlässige Prognose"
        }
    }
}

// MARK: - OccupancyTrendManager

@MainActor
class OccupancyTrendManager: ObservableObject {
    static let shared = OccupancyTrendManager()
    
    @Published var records: [OccupancyRecord] = []
    
    private let storageKey = "occupancyTrendRecords"
    private let maxRecords = 500
    private let maxAgeInDays = 90
    
    private init() {
        loadRecords()
        cleanupOldRecords()
    }
    
    func record(lineName: String, direction: String, stationName: String, occupancy: OccupancyLevel) {
        guard occupancy != .unknown else { return }
        let now = Date()
        let calendar = Calendar.current
        let record = OccupancyRecord(
            lineName: lineName, direction: direction, stationName: stationName,
            dayOfWeek: calendar.component(.weekday, from: now),
            hourOfDay: calendar.component(.hour, from: now),
            occupancy: occupancy, timestamp: now
        )
        records.append(record)
        if records.count > maxRecords { records = Array(records.suffix(maxRecords)) }
        saveRecords()
    }
    
    func trend(forLine lineName: String, direction: String, stationName: String, at date: Date = Date()) -> OccupancyTrend? {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let hourOfDay = calendar.component(.hour, from: date)
        
        let relevantRecords = records.filter {
            $0.lineName.lowercased() == lineName.lowercased() &&
            $0.direction.lowercased().contains(direction.lowercased()) &&
            $0.stationName.lowercased() == stationName.lowercased() &&
            $0.dayOfWeek == dayOfWeek && $0.hourOfDay == hourOfDay
        }
        guard !relevantRecords.isEmpty else { return nil }
        
        let avgOccupancy = calculateAverageOccupancy(from: relevantRecords)
        let confidence: TrendConfidence = relevantRecords.count >= 10 ? .high : (relevantRecords.count >= 3 ? .medium : .low)
        
        return OccupancyTrend(lineName: lineName, direction: direction, stationName: stationName,
                             dayOfWeek: dayOfWeek, hourOfDay: hourOfDay, averageOccupancy: avgOccupancy,
                             sampleCount: relevantRecords.count, confidence: confidence)
    }
    
    func clearAllData() { records = []; saveRecords() }
    
    private func calculateAverageOccupancy(from records: [OccupancyRecord]) -> OccupancyLevel {
        guard !records.isEmpty else { return .unknown }
        let avg = Double(records.reduce(0) { $0 + $1.occupancy.severityRank }) / Double(records.count)
        if avg < 1.5 { return .low }
        if avg < 2.5 { return .medium }
        return .high
    }
    
    private func cleanupOldRecords() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -maxAgeInDays, to: Date()) ?? Date()
        records = records.filter { $0.timestamp > cutoff }
        saveRecords()
    }
    
    private func saveRecords() {
        let snapshot = records
        let key = storageKey
        Task.detached(priority: .utility) {
            if let encoded = try? JSONEncoder().encode(snapshot) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([OccupancyRecord].self, from: data) { records = decoded }
    }
}
