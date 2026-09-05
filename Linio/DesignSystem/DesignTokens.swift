//
//  DesignTokens.swift
//  Linio
//
//  Apple HIG-konformes Design-System
//  Basierend auf: https://developer.apple.com/design/human-interface-guidelines
//

import SwiftUI
import UIKit

// MARK: - Design Tokens

/// Zentrales Design-System nach Apple Human Interface Guidelines
enum DesignTokens {
    
    // MARK: - Spacing (8pt Grid System)
    
    enum Spacing {
        /// 4pt - Minimaler Abstand
        static let xxs: CGFloat = 4
        /// 8pt - Sehr kleiner Abstand
        static let xs: CGFloat = 8
        /// 12pt - Kleiner Abstand
        static let sm: CGFloat = 12
        /// 16pt - Standard-Abstand
        static let md: CGFloat = 16
        /// 20pt - Mittlerer Abstand
        static let lg: CGFloat = 20
        /// 24pt - Großer Abstand
        static let xl: CGFloat = 24
        /// 32pt - Sehr großer Abstand
        static let xxl: CGFloat = 32
        /// 48pt - Section spacing
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        /// 6pt - Kleine Elemente
        static let small: CGFloat = 6
        /// 10pt - Buttons
        static let medium: CGFloat = 10
        /// 14pt - Cards
        static let large: CGFloat = 14
        /// 20pt - Sheets
        static let xlarge: CGFloat = 20
    }
    
    // MARK: - Touch Targets (Apple HIG: 44pt minimum)
    
    enum TouchTarget {
        static let minimum: CGFloat = 44
        static let recommended: CGFloat = 48
        static let large: CGFloat = 56
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let fast: SwiftUI.Animation = .easeOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.35)
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
        static let bounce: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.6)
    }
    
    // MARK: - Shadows (subtil nach Apple HIG)
    
    enum Shadow {
        static let small = ShadowStyle(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        static let large = ShadowStyle(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 4)
    }
    
    // MARK: - Icon Sizes
    
    enum IconSize {
        static let tiny: CGFloat = 12
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 28
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
