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
    static let enableOfflineMode = false
    static let enableAutoBackup = true
    static let enableDetailedLogging = false
    
    // MARK: - API Configuration
    static let requestTimeout: TimeInterval = 30.0
    static let resourceTimeout: TimeInterval = 60.0
    
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
        var errors: [String] = []
        
        if teamID == "YOUR_TEAM_ID" {
            let msg = "⚠️ teamID nicht konfiguriert - App Group wird nicht funktionieren"
            errors.append(msg)
            #if DEBUG
            print("[AppConfiguration] WARNING: \(msg)")
            #endif
        }
        
        return errors
    }
}