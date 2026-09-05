//
//  SemanticColors.swift
//  Linio
//
//  Semantische Farben nach Apple HIG
//  Automatisch adaptiv für Light/Dark Mode
//

import SwiftUI
import UIKit

// MARK: - Semantic Colors

/// Semantische Farben die automatisch für Light/Dark Mode adaptieren
enum SemanticColor {
    
    // MARK: - Labels (Text)
    
    /// Primärer Text - höchste Wichtigkeit
    static let label = Color(uiColor: .label)
    /// Sekundärer Text
    static let secondaryLabel = Color(uiColor: .secondaryLabel)
    /// Tertiärer Text
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
    /// Quaternärer Text - Placeholder
    static let quaternaryLabel = Color(uiColor: .quaternaryLabel)
    
    // MARK: - Backgrounds
    
    /// System Background
    static let systemBackground = Color(uiColor: .systemBackground)
    /// Sekundärer Hintergrund - Cards
    static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    /// Tertiärer Hintergrund
    static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
    
    // MARK: - Grouped Backgrounds
    
    static let systemGroupedBackground = Color(uiColor: .systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    
    // MARK: - Fills
    
    static let systemFill = Color(uiColor: .systemFill)
    static let secondarySystemFill = Color(uiColor: .secondarySystemFill)
    static let tertiarySystemFill = Color(uiColor: .tertiarySystemFill)
    static let quaternarySystemFill = Color(uiColor: .quaternarySystemFill)
    
    // MARK: - Separators
    
    static let separator = Color(uiColor: .separator)
    static let opaqueSeparator = Color(uiColor: .opaqueSeparator)
    
    // MARK: - System Colors (Accessible)
    
    static let systemRed = Color(uiColor: .systemRed)
    static let systemOrange = Color(uiColor: .systemOrange)
    static let systemYellow = Color(uiColor: .systemYellow)
    static let systemGreen = Color(uiColor: .systemGreen)
    static let systemMint = Color(uiColor: .systemMint)
    static let systemTeal = Color(uiColor: .systemTeal)
    static let systemCyan = Color(uiColor: .systemCyan)
    static let systemBlue = Color(uiColor: .systemBlue)
    static let systemIndigo = Color(uiColor: .systemIndigo)
    static let systemPurple = Color(uiColor: .systemPurple)
    static let systemPink = Color(uiColor: .systemPink)
    static let systemBrown = Color(uiColor: .systemBrown)
    
    // MARK: - Grays
    
    static let systemGray = Color(uiColor: .systemGray)
    static let systemGray2 = Color(uiColor: .systemGray2)
    static let systemGray3 = Color(uiColor: .systemGray3)
    static let systemGray4 = Color(uiColor: .systemGray4)
    static let systemGray5 = Color(uiColor: .systemGray5)
    static let systemGray6 = Color(uiColor: .systemGray6)
    
    // MARK: - Links & Tint
    
    static let link = Color(uiColor: .link)
    static let tint = Color.accentColor
    
    // MARK: - Onboarding Gradients (Dark Theme)
    
    /// Onboarding-Farbpalette basierend auf Stone-Grays
    static let onboardingDark = Color(hex: "#0c0a09")
    static let onboardingMedium = Color(hex: "#1c1917")
    static let onboardingLight = Color(hex: "#292524")
}

// MARK: - Material Effects

enum MaterialEffect {
    static let ultraThin = Material.ultraThinMaterial
    static let thin = Material.thinMaterial
    static let regular = Material.regularMaterial
    static let thick = Material.thickMaterial
    static let bar = Material.bar
}
