//
//  AccessibilityModifiers.swift
//  Linio
//
//  Zusätzliche Accessibility-Erweiterungen nach Apple HIG
//  Ergänzt die bestehenden AccessibilityHelpers
//

import SwiftUI

// MARK: - HIG Accessibility View Modifiers

extension View {
    
    /// Fügt eine umfassende Accessibility-Beschreibung hinzu (HIG)
    func accessibleElement(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Button mit korrektem Accessibility-Labeling (HIG)
    func accessibleButton(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Doppeltippen zum Aktivieren")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Headings für VoiceOver Navigation (HIG)
    func accessibleHeading() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Accessibility Helpers

enum AccessibilityHelper {
    
    /// Formatiert Zeitangaben für VoiceOver
    static func formatTimeForVoiceOver(_ time: String) -> String {
        // "14:30" → "14 Uhr 30"
        let components = time.split(separator: ":")
        guard components.count == 2 else { return time }
        return "\(components[0]) Uhr \(components[1])"
    }
    
    /// Formatiert Verspätungen für VoiceOver
    static func formatDelayForVoiceOver(_ minutes: Int) -> String {
        switch minutes {
        case 0: return "pünktlich"
        case 1: return "1 Minute Verspätung"
        case let m where m > 0: return "\(m) Minuten Verspätung"
        case -1: return "1 Minute früher"
        default: return "\(abs(minutes)) Minuten früher"
        }
    }
    
    /// Formatiert Countdown für VoiceOver
    static func formatCountdownForVoiceOver(_ minutes: Int) -> String {
        switch minutes {
        case 0: return "fährt jetzt"
        case 1: return "in 1 Minute"
        default: return "in \(minutes) Minuten"
        }
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Skaliert Text-Größe mit Dynamic Type, limitiert auf einen Bereich
    func dynamicTypeRange(_ range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }
    
    /// Standard Dynamic Type Range für die App
    func appDynamicType() -> some View {
        self.dynamicTypeSize(.xSmall ... .accessibility2)
    }
}

// MARK: - Contrast Support

extension View {
    /// Passt Farbe basierend auf Increased Contrast Einstellung an
    func adaptiveColor(
        normal: Color,
        highContrast: Color
    ) -> some View {
        self.modifier(AdaptiveColorModifier(normal: normal, highContrast: highContrast))
    }
}

private struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    let normal: Color
    let highContrast: Color
    
    func body(content: Content) -> some View {
        content.foregroundStyle(contrast == .increased ? highContrast : normal)
    }
}
