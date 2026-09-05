//
//  AppColorPalette.swift
//  Linio
//
//  Zentrale Farbpalette für die App
//  Neue Farbgebung: Blaugrau-Palette
//

import SwiftUI

// MARK: - App Color Palette

/// Zentrale Farbpalette für die gesamte App
/// Basierend auf der neuen Blaugrau-Palette
enum AppColorPalette {
    
    // MARK: - Primary Colors
    
    /// Primärfarbe - Mittleres Blaugrau #6A89A7
    static let primary = Color(hex: "#6A89A7")
    
    /// Light Accent - Helles Blau #BDDDFC
    static let lightAccent = Color(hex: "#BDDDFC")
    
    /// Sekundärfarbe - Mittleres Blau #88BDF2
    static let secondary = Color(hex: "#88BDF2")
    
    /// Dark Surface - Dunkles Blaugrau #384959
    static let darkSurface = Color(hex: "#384959")
    
    // MARK: - Derived Colors (Opacity Variants)
    
    /// Leichte Variante der Primärfarbe
    static var primaryLight: Color { primary.opacity(0.3) }
    
    /// Sehr leichte Variante für Hintergründe
    static var primarySubtle: Color { primary.opacity(0.1) }
    
    /// Dunklere Variante der Primärfarbe
    static var primaryDark: Color { darkSurface }
    
    // MARK: - Gradients
    
    /// Standard Gradient (Primary zu Secondary)
    static let standardGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Light Gradient (Light Accent zu Secondary)
    static let lightGradient = LinearGradient(
        colors: [lightAccent, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Dark Gradient (Dark Surface zu Primary)
    static let darkGradient = LinearGradient(
        colors: [darkSurface, primary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - UIColor Variants (für UIKit Kompatibilität)
    
    static var primaryUIColor: UIColor {
        UIColor(red: 106/255, green: 137/255, blue: 167/255, alpha: 1)
    }
    
    static var secondaryUIColor: UIColor {
        UIColor(red: 136/255, green: 189/255, blue: 242/255, alpha: 1)
    }
    
    static var lightAccentUIColor: UIColor {
        UIColor(red: 189/255, green: 221/255, blue: 252/255, alpha: 1)
    }
    
    static var darkSurfaceUIColor: UIColor {
        UIColor(red: 56/255, green: 73/255, blue: 89/255, alpha: 1)
    }
}

// MARK: - Color Scheme Adaptive

extension AppColorPalette {
    
    /// Adaptiver Primary für Light/Dark Mode
    /// Light Mode: #6A89A7, Dark Mode: #88BDF2
    static func adaptivePrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondary : primary
    }
    
    /// Adaptiver Hintergrund
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkSurface : lightAccent
    }
}
