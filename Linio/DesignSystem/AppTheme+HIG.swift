//
//  AppTheme+HIG.swift
//  Linio
//
//  HIG-konforme Erweiterungen für AppTheme
//  Bietet Brücke zwischen bestehendem Design und Apple HIG
//

import SwiftUI

// MARK: - AppTheme HIG Extensions

extension AppTheme {
    
    // MARK: - HIG-konforme Aliase
    
    /// Primärer Hintergrund (ersetzt canvas)
    static var background: Color { SemanticColor.systemBackground }
    
    /// Gruppierter Hintergrund für Listen
    static var groupedBackground: Color { SemanticColor.systemGroupedBackground }
    
    /// Card Hintergrund (HIG-konform)
    static var cardSurface: Color { SemanticColor.secondarySystemGroupedBackground }
    
    /// Primärer Text (ersetzt ink)
    static var textPrimary: Color { SemanticColor.label }
    
    /// Sekundärer Text (ersetzt muted)
    static var textSecondary: Color { SemanticColor.secondaryLabel }
    
    /// Tertiärer Text
    static var textTertiary: Color { SemanticColor.tertiaryLabel }
    
    /// Separator (ersetzt hairline)
    static var divider: Color { SemanticColor.separator }
    
    /// Fill für UI-Elemente
    static var fill: Color { SemanticColor.systemFill }
    
    // MARK: - Semantic Status Colors (HIG)
    
    /// Fehler-Farbe (System Red)
    static var error: Color { SemanticColor.systemRed }
    
    /// Erfolgs-Farbe (System Green)
    static var success: Color { SemanticColor.systemGreen }
    
    /// Warn-Farbe (System Orange)
    static var warning: Color { SemanticColor.systemOrange }
    
    /// Info-Farbe (System Blue)
    static var info: Color { SemanticColor.systemBlue }
    
    // MARK: - Transport Colors (App-spezifisch, HIG-konform)
    
    /// Tram-Farbe
    static var tramColor: Color { SemanticColor.systemRed }
    
    /// Bus-Farbe
    static var busColor: Color { SemanticColor.systemPurple }
    
    /// S-Bahn-Farbe
    static var sBahnColor: Color { SemanticColor.systemGreen }
    
    // MARK: - Spacing Shortcuts
    
    static var spacingXS: CGFloat { DesignTokens.Spacing.xs }
    static var spacingSM: CGFloat { DesignTokens.Spacing.sm }
    static var spacingMD: CGFloat { DesignTokens.Spacing.md }
    static var spacingLG: CGFloat { DesignTokens.Spacing.lg }
    static var spacingXL: CGFloat { DesignTokens.Spacing.xl }
    
    // MARK: - Corner Radius Shortcuts
    
    static var radiusSmall: CGFloat { DesignTokens.CornerRadius.small }
    static var radiusMedium: CGFloat { DesignTokens.CornerRadius.medium }
    static var radiusLarge: CGFloat { DesignTokens.CornerRadius.large }
}

// MARK: - View Modifiers

extension View {
    /// Wendet Liquid Glass Card-Styling an
    func higCard(padding: CGFloat = DesignTokens.Spacing.md, intensity: LiquidGlassIntensity = .standard) -> some View {
        self
            .padding(padding)
            .background(
                LiquidGlassBackground(
                    cornerRadius: DesignTokens.CornerRadius.large,
                    intensity: intensity
                )
            )
    }
    
    /// Wendet HIG-konformen Hintergrund an
    func higBackground() -> some View {
        self.background(SemanticColor.systemGroupedBackground.ignoresSafeArea())
    }
    
    /// Standard Touch-Target sicherstellen (44pt minimum)
    func higTouchTarget() -> some View {
        self.frame(minWidth: DesignTokens.TouchTarget.minimum, minHeight: DesignTokens.TouchTarget.minimum)
    }
    
    /// Liquid Glass Hintergrund
    func higMaterial(_ intensity: LiquidGlassIntensity = .standard) -> some View {
        self.background(
            LiquidGlassBackground(
                cornerRadius: DesignTokens.CornerRadius.large,
                intensity: intensity
            )
        )
    }
}
