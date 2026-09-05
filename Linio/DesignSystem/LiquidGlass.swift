//
//  LiquidGlass.swift
//  Linio
//
//  Apple Liquid Glass Effekt für SwiftUI
//  Inspiriert von iOS 26 Glassmorphismus Design
//

import SwiftUI

// MARK: - Liquid Glass Intensity

enum LiquidGlassIntensity {
    case subtle      // Leichter Effekt
    case standard    // Standard Apple Glass
    case prominent   // Stärkerer Effekt
    
    var blurRadius: CGFloat {
        switch self {
        case .subtle: return 8
        case .standard: return 16
        case .prominent: return 24
        }
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .subtle: return 0.4
        case .standard: return 0.6
        case .prominent: return 0.75
        }
    }
    
    var borderOpacity: Double {
        switch self {
        case .subtle: return 0.2
        case .standard: return 0.35
        case .prominent: return 0.5
        }
    }
    
    var highlightOpacity: Double {
        switch self {
        case .subtle: return 0.15
        case .standard: return 0.25
        case .prominent: return 0.4
        }
    }
}

// MARK: - Liquid Glass Background

struct LiquidGlassBackground: View {
    var cornerRadius: CGFloat
    var intensity: LiquidGlassIntensity
    var isPressed: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDark: Bool { colorScheme == .dark }
    
    var body: some View {
        ZStack {
            // Layer 1: Blur Background
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Layer 2: Tinted Overlay
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    isDark
                        ? Color.white.opacity(0.08 * intensity.backgroundOpacity)
                        : Color.black.opacity(0.03 * intensity.backgroundOpacity)
                )
            
            // Layer 3: Top Highlight (Lichtreflektion)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(intensity.highlightOpacity),
                            Color.white.opacity(intensity.highlightOpacity * 0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            
            // Layer 4: Edge Glow Border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(intensity.borderOpacity),
                            Color.white.opacity(intensity.borderOpacity * 0.3),
                            Color.white.opacity(intensity.borderOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            
            // Layer 5: Press State
            if isPressed {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.1))
            }
        }
    }
}

// MARK: - Liquid Glass Card

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var intensity: LiquidGlassIntensity
    
    init(
        padding: CGFloat = DesignTokens.Spacing.md,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.large,
        intensity: LiquidGlassIntensity = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                LiquidGlassBackground(
                    cornerRadius: cornerRadius,
                    intensity: intensity
                )
            )
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    var intensity: LiquidGlassIntensity = .standard
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                LiquidGlassBackground(
                    cornerRadius: cornerRadius,
                    intensity: intensity,
                    isPressed: configuration.isPressed
                )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - View Extension

extension View {
    /// Fügt einen Liquid Glass Effekt hinzu
    func liquidGlass(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.large,
        intensity: LiquidGlassIntensity = .standard
    ) -> some View {
        self.background(
            LiquidGlassBackground(
                cornerRadius: cornerRadius,
                intensity: intensity
            )
        )
    }
}

// MARK: - Button Style Extension

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle { LiquidGlassButtonStyle() }
    
    static func liquidGlass(
        intensity: LiquidGlassIntensity = .standard,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium
    ) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(intensity: intensity, cornerRadius: cornerRadius)
    }
}
