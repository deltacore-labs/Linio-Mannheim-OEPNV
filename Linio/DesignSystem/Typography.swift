//
//  Typography.swift
//  Linio
//
//  Typografie nach Apple HIG mit Dynamic Type Support
//  Schriftart: San Francisco (SF Pro) – Apple System Font
//

import SwiftUI
import UIKit

// MARK: - Typography

/// Typografie nach Apple HIG mit Dynamic Type
/// Verwendet durchgehend San Francisco (SF Pro) als Systemschrift
enum Typography {
    
    // MARK: - Titles
    
    /// Large Title - 34pt (Navigation)
    static let largeTitle = Font.largeTitle
    /// Title 1 - 28pt
    static let title = Font.title
    /// Title 2 - 22pt
    static let title2 = Font.title2
    /// Title 3 - 20pt
    static let title3 = Font.title3
    
    // MARK: - Headlines
    
    /// Headline - 17pt, Semibold
    static let headline = Font.headline
    /// Subheadline - 15pt
    static let subheadline = Font.subheadline
    
    // MARK: - Body
    
    /// Body - 17pt (Standard)
    static let body = Font.body
    /// Callout - 16pt
    static let callout = Font.callout
    
    // MARK: - Small Text
    
    /// Footnote - 13pt
    static let footnote = Font.footnote
    /// Caption - 12pt
    static let caption = Font.caption
    /// Caption 2 - 11pt
    static let caption2 = Font.caption2
    
    // MARK: - Custom (San Francisco)
    
    static func body(weight: Font.Weight) -> Font {
        Font.body.weight(weight)
    }
    
    static func headline(weight: Font.Weight) -> Font {
        Font.headline.weight(weight)
    }
    
    /// San Francisco Mono für Zahlen (SF Mono)
    static func monospacedDigit(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .default).monospacedDigit()
    }
    
    /// San Francisco Rounded (SF Pro Rounded)
    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }
    
    /// Skalierte Schrift mit Dynamic Type Support (San Francisco)
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        Font.system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: design)
    }
    
    /// Display Font (San Francisco statt Serif)
    static func display(size: CGFloat, weight: Font.Weight = .light) -> Font {
        Font.system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: .default)
    }
    
    /// Mono Font für Zeiten/Zahlen (San Francisco mit Monospaced Digits)
    static func mono(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: .default).monospacedDigit()
    }
    
    // MARK: - Legacy Aliases (für Rückwärtskompatibilität)
    
    /// @deprecated Verwende display() stattdessen
    static func serif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        display(size: size, weight: weight)
    }
}
