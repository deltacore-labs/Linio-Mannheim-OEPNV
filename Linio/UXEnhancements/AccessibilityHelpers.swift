//
//  AccessibilityHelpers.swift
//  Linio
//
//  Accessibility-Verbesserungen und Hilfsfunktionen
//

import SwiftUI

// MARK: - Accessibility Announce Modifier

struct AccessibilityAnnounceModifier: ViewModifier {
    let message: String
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    AccessibilityNotification.Announcement(message).post()
                }
            }
    }
}

extension View {
    /// Kündigt eine Nachricht für VoiceOver an wenn die View erscheint
    func accessibilityAnnounce(_ message: String, delay: Double = 0.5) -> some View {
        modifier(AccessibilityAnnounceModifier(message: message, delay: delay))
    }
}

// MARK: - Loading State Accessibility

struct LoadingAccessibilityModifier: ViewModifier {
    let isLoading: Bool
    let loadingMessage: String
    let loadedMessage: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityValue(isLoading ? loadingMessage : "")
            .onChange(of: isLoading) { wasLoading, isNowLoading in
                if wasLoading && !isNowLoading, let loadedMessage {
                    AccessibilityNotification.Announcement(loadedMessage).post()
                }
            }
    }
}

extension View {
    /// Fügt Accessibility-Feedback für Ladezustände hinzu
    func accessibilityLoading(
        _ isLoading: Bool,
        loadingMessage: String = "Wird geladen",
        loadedMessage: String? = "Fertig geladen"
    ) -> some View {
        modifier(LoadingAccessibilityModifier(
            isLoading: isLoading,
            loadingMessage: loadingMessage,
            loadedMessage: loadedMessage
        ))
    }
}

// MARK: - Trip Accessibility Helper

struct TripAccessibilityHelper {
    private static let formatter = DateFormattingHelper.shared
    
    /// Generiert eine vollständige Accessibility-Beschreibung für eine Verbindung
    static func description(for trip: DetailedTrip) -> String {
        let dep = formatter.formatTime(trip.startTime)
        let arr = formatter.formatTime(trip.endTime)
        
        var components: [String] = []
        components.append("Verbindung von \(dep) bis \(arr)")
        
        // Dauer berechnen
        if let depDate = formatter.parseISO8601(trip.startTime),
           let arrDate = formatter.parseISO8601(trip.endTime) {
            let minutes = Int(arrDate.timeIntervalSince(depDate) / 60)
            components.append("Dauer \(minutes) Minuten")
        }
        
        // Umstiege
        if trip.interchanges == 0 {
            components.append("Direktverbindung")
        } else {
            let umstiege = trip.interchanges == 1 ? "Umstieg" : "Umstiege"
            components.append("\(trip.interchanges) \(umstiege)")
        }
        
        // Linien
        let timedLegs = trip.legs.filter { $0.isTimedLeg }
        let lineNames = timedLegs.compactMap { $0.serviceName }.joined(separator: ", ")
        if !lineNames.isEmpty {
            components.append("Linien: \(lineNames)")
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Generiert Accessibility-Label für Verspätung
    static func delayDescription(minutes: Int) -> String {
        if minutes <= 0 {
            return "Pünktlich"
        } else if minutes == 1 {
            return "1 Minute Verspätung"
        } else {
            return "\(minutes) Minuten Verspätung"
        }
    }
    
    /// Generiert Accessibility-Label für Auslastung
    static func occupancyDescription(_ level: OccupancyLevel) -> String {
        switch level {
        case .low: return "Geringe Auslastung, viele Sitzplätze verfügbar"
        case .medium: return "Mittlere Auslastung, einige Sitzplätze verfügbar"
        case .high: return "Hohe Auslastung, wenige Sitzplätze verfügbar"
        case .unknown: return "Auslastung unbekannt"
        }
    }
}

// MARK: - Accessibility Container

struct AccessibilityContainerModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    /// Fasst Kind-Elemente zu einem Accessibility-Element zusammen
    func accessibilityContainer(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibilityContainerModifier(label: label, hint: hint, traits: traits))
    }
}

// MARK: - Semantic Button Modifier

extension View {
    /// Markiert eine View als Button mit passendem Label und Hint
    func accessibilityButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Doppeltippen zum Aktivieren")
            .accessibilityAddTraits(.isButton)
    }
}
