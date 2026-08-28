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

// MARK: - Dynamic Type Support

struct ScaledFontModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    let baseSize: CGFloat
    let weight: Font.Weight
    let maxSize: CGFloat
    
    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight))
    }
    
    private var scaledSize: CGFloat {
        let scale: CGFloat
        switch dynamicTypeSize {
        case .xSmall: scale = 0.8
        case .small: scale = 0.9
        case .medium: scale = 1.0
        case .large: scale = 1.1
        case .xLarge: scale = 1.2
        case .xxLarge: scale = 1.3
        case .xxxLarge: scale = 1.4
        case .accessibility1: scale = 1.6
        case .accessibility2: scale = 1.8
        case .accessibility3: scale = 2.0
        case .accessibility4: scale = 2.2
        case .accessibility5: scale = 2.4
        @unknown default: scale = 1.0
        }
        return min(baseSize * scale, maxSize)
    }
}

extension View {
    /// Skaliert eine Font basierend auf Dynamic Type, mit Maximum
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, maxSize: CGFloat = 100) -> some View {
        modifier(ScaledFontModifier(baseSize: size, weight: weight, maxSize: maxSize))
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let reducedAnimation: Animation?
    let fullAnimation: Animation
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? reducedAnimation : fullAnimation, value: UUID())
    }
}

extension View {
    /// Verwendet alternative Animation wenn "Bewegung reduzieren" aktiv ist
    func motionSensitiveAnimation(
        reduced: Animation? = nil,
        full: Animation = .default
    ) -> some View {
        modifier(ReduceMotionModifier(reducedAnimation: reduced, fullAnimation: full))
    }
}

// MARK: - Departure Accessibility

struct DepartureAccessibilityHelper {
    private static let formatter = DateFormattingHelper.shared
    
    /// Generiert Accessibility-Label für eine Abfahrt
    static func label(
        lineName: String,
        destination: String,
        departureTime: String,
        delayMinutes: Int?,
        platform: String?
    ) -> String {
        var components: [String] = []
        
        // Linie und Ziel
        components.append("Linie \(lineName) nach \(destination)")
        
        // Abfahrtszeit
        let time = formatter.formatTime(departureTime)
        components.append("Abfahrt um \(time) Uhr")
        
        // Verspätung
        if let delay = delayMinutes, delay > 0 {
            components.append(TripAccessibilityHelper.delayDescription(minutes: delay))
        } else if delayMinutes == 0 {
            components.append("Pünktlich")
        }
        
        // Gleis/Steig
        if let platform = platform, !platform.isEmpty {
            components.append("Steig \(platform)")
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Generiert relative Zeitangabe für VoiceOver
    static func relativeTimeLabel(departureTime: String) -> String {
        guard let date = formatter.parseISO8601(departureTime) else { return "" }
        let minutes = Int(date.timeIntervalSinceNow / 60)
        
        if minutes < 0 {
            return "Bereits abgefahren"
        } else if minutes == 0 {
            return "Fährt jetzt"
        } else if minutes == 1 {
            return "In 1 Minute"
        } else if minutes < 60 {
            return "In \(minutes) Minuten"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "In \(hours) Stunde\(hours == 1 ? "" : "n")"
            }
            return "In \(hours) Stunde\(hours == 1 ? "" : "n") und \(remainingMinutes) Minuten"
        }
    }
}

// MARK: - Accessibility Rotor Actions

struct RotorAccessibilityModifier: ViewModifier {
    let rotorLabel: String
    let rotorHint: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(rotorLabel)
            .accessibilityHint(rotorHint ?? "")
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// Markiert eine View als Rotor-Ziel für schnelle Navigation
    func accessibilityRotorTarget(label: String, hint: String? = nil) -> some View {
        modifier(RotorAccessibilityModifier(rotorLabel: label, rotorHint: hint))
    }
}
