//
//  LineColors.swift
//  Linio
//
//  Offizielle RNV/VRN Linienfarben
//  Diese Brand-Farben sind festgelegt und sollten nicht geändert werden
//

import SwiftUI

// MARK: - Line Colors

/// Offizielle Linienfarben für RNV/VRN Transportlinien
enum LineColors {
    
    // MARK: - Tram Lines (Mannheim/Ludwigshafen)
    
    /// Tram 1 - Rosa
    static let tram1 = Color(hex: "#f39b9a")
    /// Tram 3 - Gold
    static let tram3 = Color(hex: "#d6ad00")
    /// Tram 4/4A - Rot
    static let tram4 = Color(hex: "#e30613")
    /// Tram 5/5A - Grün
    static let tram5 = Color(hex: "#00975f")
    /// Tram 6 - Braun
    static let tram6 = Color(hex: "#956c29")
    /// Tram 7 - Gelb
    static let tram7 = Color(hex: "#fecc00")
    
    // MARK: - Regional Bus Lines
    
    /// Bus 60 - Lila
    static let bus60 = Color(hex: "#4e2583")
    /// Bus 61 - Hellblau
    static let bus61 = Color(hex: "#4a96d1")
    
    // MARK: - Transport Types
    
    /// S-Bahn - Grün
    static let sBahn = Color(hex: "#00975f")
    /// Regional - Lila
    static let regional = Color(hex: "#4e2583")
    /// Fernverkehr - Blau
    static let longDistance = Color(hex: "#4a96d1")
    /// Tram Default - Rot
    static let tramDefault = Color(hex: "#e30613")
    /// Bus Default - Blau
    static let busDefault = Color(hex: "#4a96d1")
    /// Fallback - Dunkelgrau
    static let fallback = Color(hex: "#292524")
}

// MARK: - Germany Flag Colors (for Deutschlandticket)

enum GermanyFlagColors {
    static let black = Color(hex: "#000000")
    static let red = Color(hex: "#DD0000")
    static let gold = Color(hex: "#FFCE00")
}

// MARK: - D-Ticket Logo Colors

/// Spezifische Farben für das Deutschlandticket-Logo
enum DTicketLogoColors {
    // Black bars
    static let blackBar = Color(hex: "#111111")
    
    // Red gradient bars
    static let redDark = Color(hex: "#5E0000")
    static let redLight = Color(hex: "#CC1A00")
    static let redMid = Color(hex: "#C01800")
    
    // Yellow gradient bars
    static let yellowDark = Color(hex: "#DE4400")
    static let yellowMid = Color(hex: "#E04800")
    static let yellowLight = Color(hex: "#F8CC00")
}

// MARK: - Ticket Status Colors

/// Farben für Ticket-Ablaufstatus
enum TicketStatusColors {
    /// Abgelaufen - Rot
    static let expired = Color(hex: "#CC2200")
    /// Dringend - Orange
    static let urgent = Color(hex: "#E05000")
    /// Warnung - Gelb-Orange
    static let warning = Color(hex: "#C07800")
    /// Gültig - Grün
    static let valid = Color(hex: "#1e7e34")
}
