//
//  AppConfiguration.swift
//  Linio
//


import Foundation

struct AppConfiguration {
    // ✅ ZENTRALE APP GROUP ID
    static let appGroupID = "group.com.stefanfriedrich.rnvapp"
    
    // ✅ Apple Team ID (aus Secrets.xcconfig → WALLET_TEAM_ID)
    static let teamID = "A4HCRKN53K"

    // MARK: - Shared Keychain (App ↔ Widget)
    static let widgetKeychainAccessGroup = teamID + "." + appGroupID
    static let widgetKeychainService = "com.stefanfriedrich.rnvapp.widget"
    static let widgetKeychainTokenKey = "widgetAccessToken"
    
    // MARK: - Feature Flags
    static let enableAutoBackup = true
    
    // MARK: - API Configuration
    static let requestTimeout: TimeInterval = 30.0
    static let resourceTimeout: TimeInterval = 60.0
    static let fallbackGraphQLURL = "https://graphql-sandbox-dds.rnv-online.de/"
    
    // MARK: - Hub-Stationen (Hauptknotenpunkte für Direktabfragen)
    static let hubStationNames: [String] = [
        "Mannheim Hauptbahnhof",
        "Heidelberg Hauptbahnhof",
        "Paradeplatz"
    ]

    // MARK: - Update Intervals (adaptiv)
    static let updateIntervalBeforeDeparture: TimeInterval = 30 // 30 Sekunden
    static let updateIntervalDuringJourney: TimeInterval = 10   // 10 Sekunden
    static let updateIntervalNearArrival: TimeInterval = 5      // 5 Sekunden
    
    // MARK: - Validation
    static func validateConfiguration() -> [String] {
        var issues: [String] = []
        let info = Bundle.main.infoDictionary ?? [:]
        func isUnresolved(_ key: String) -> Bool {
            guard let val = info[key] as? String, !val.isEmpty else { return true }
            return val.contains("$(")
        }
        if isUnresolved("RNV_GRAPHQL_URL")   { issues.append("RNV_GRAPHQL_URL fehlt oder nicht aufgelöst") }
        if isUnresolved("RNV_CLIENT_ID")     { issues.append("RNV_CLIENT_ID fehlt oder nicht aufgelöst") }
        if isUnresolved("RNV_CLIENT_SECRET") { issues.append("RNV_CLIENT_SECRET fehlt oder nicht aufgelöst") }
        return issues
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKey: String {
        case activeTrips
        case savedTripData
        case widgetAccessTokenExpiry
        case widgetGraphQLURL
        case widgetFavoriteStations
        case favoriteStations
        case occupancyTrendRecords
    }
}
