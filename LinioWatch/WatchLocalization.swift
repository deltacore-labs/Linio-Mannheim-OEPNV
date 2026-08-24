//
//  WatchLocalization.swift
//  LinioWatch
//
//  Dynamische Lokalisierung basierend auf iPhone-Spracheinstellung

import Foundation
import SwiftUI

// MARK: - Localization Manager

@MainActor
final class WatchLocalizationManager: ObservableObject {
    static let shared = WatchLocalizationManager()
    
    @Published var language: String = "de" {
        didSet {
            UserDefaults.standard.set(language, forKey: "watchAppLanguage")
        }
    }
    
    private init() {
        // Gespeicherte Sprache laden oder Default
        language = UserDefaults.standard.string(forKey: "watchAppLanguage") ?? "de"
    }
    
    func updateFromContext(_ context: [String: Any]) {
        if let lang = context["appLanguage"] as? String {
            language = lang
        }
    }
    
    /// Übersetzt einen deutschen Key in die aktuelle Sprache (MainActor)
    func localized(_ key: String) -> String {
        guard language == "en", let translation = Self.translations[key] else {
            return key
        }
        return translation
    }
    
    /// Thread-safe Übersetzung ohne MainActor - liest direkt aus UserDefaults
    nonisolated static func localizedStatic(_ key: String) -> String {
        let lang = UserDefaults.standard.string(forKey: "watchAppLanguage") ?? "de"
        guard lang == "en", let translation = translations[key] else {
            return key
        }
        return translation
    }
    
    // MARK: - Übersetzungen (Deutsch → Englisch)
    
    private static let translations: [String: String] = [
        // Navigation & Tabs
        "Fahrt": "Trip",
        "Geplant": "Planned",
        "Abfahrten": "Departures",
        "Suche": "Search",
        "Fußweg": "Walk",
        
        // Aktive Fahrt
        "Aktive Fahrt": "Active Trip",
        "Keine aktive Fahrt": "No Active Trip",
        "Starte eine Live Activity\nauf dem iPhone": "Start a Live Activity\non your iPhone",
        "Bald": "Soon",
        "Fährt": "En Route",
        "Da": "Arrived",
        "Abfahrt": "Departure",
        "Ankunft": "Arrival",
        "Umstieg": "Transfer",
        "in": "in",
        "min": "min",
        "Unterwegs": "En Route",
        "Angekommen": "Arrived",
        
        // Geplante Fahrten
        "Geplante Fahrten": "Planned Trips",
        "Keine geplanten Fahrten": "No Planned Trips",
        "Plane Fahrten in der\niPhone-App": "Plan trips in the\niPhone app",
        
        // Abfahrten
        "Keine Abfahrten": "No Departures",
        "iPhone nicht erreichbar": "iPhone Unreachable",
        "Laden": "Load",
        "Erneut": "Retry",
        "Haltestelle": "Stop",
        "Gleis": "Platform",
        "jetzt": "now",
        
        // Verbindungssuche
        "Verbindungen": "Connections",
        "Von": "From",
        "Nach": "To",
        "Suchen": "Search",
        "Keine Verbindungen gefunden": "No Connections Found",
        "Bitte Start und Ziel wählen": "Please select start and destination",
        
        // Fußweg/Workout
        "Fußweg zur Haltestelle": "Walk to Stop",
        "Starten": "Start",
        "Beenden": "End",
        "Aktiv": "Active",
        "Ziel": "Destination",
        
        // Allgemein
        "Fehler": "Error",
        "Laden...": "Loading...",
        "Aktualisieren": "Refresh",
    ]
}

// MARK: - SwiftUI Extension für einfache Nutzung

extension String {
    /// Übersetzt den String in die aktuelle Watch-Sprache (thread-safe)
    var localized: String {
        WatchLocalizationManager.localizedStatic(self)
    }
}

// MARK: - LocalizedText View

/// Text-View mit automatischer Lokalisierung
struct LocalizedText: View {
    let key: String
    @ObservedObject private var localization = WatchLocalizationManager.shared
    
    init(_ key: String) {
        self.key = key
    }
    
    var body: some View {
        Text(localization.localized(key))
    }
}
