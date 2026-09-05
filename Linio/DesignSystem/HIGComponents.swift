//
//  HIGComponents.swift
//  Linio
//
//  Apple HIG-konforme wiederverwendbare Komponenten
//

import SwiftUI

// MARK: - HIG Card (Liquid Glass)

/// Apple HIG-konforme Card mit Liquid Glass Effekt
struct HIGCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DesignTokens.Spacing.md
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.large
    var intensity: LiquidGlassIntensity = .standard
    
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

// MARK: - HIG Button Styles (Liquid Glass)

struct HIGPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.minimum)
            .background(
                ZStack {
                    // Accent Color Base
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                        .fill(isEnabled ? Color.accentColor : SemanticColor.systemGray3)
                    
                    // Liquid Glass Highlight
                    LiquidGlassBackground(
                        cornerRadius: DesignTokens.CornerRadius.medium,
                        intensity: .subtle,
                        isPressed: configuration.isPressed
                    )
                    .opacity(0.3)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
    }
}

struct HIGSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(isEnabled ? Color.accentColor : SemanticColor.systemGray)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.minimum)
            .background(
                LiquidGlassBackground(
                    cornerRadius: DesignTokens.CornerRadius.medium,
                    intensity: .subtle,
                    isPressed: configuration.isPressed
                )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignTokens.Animation.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == HIGPrimaryButtonStyle {
    static var higPrimary: HIGPrimaryButtonStyle { HIGPrimaryButtonStyle() }
}

extension ButtonStyle where Self == HIGSecondaryButtonStyle {
    static var higSecondary: HIGSecondaryButtonStyle { HIGSecondaryButtonStyle() }
}

// MARK: - HIG Section Header

struct HIGSectionHeader: View {
    let title: String
    var action: (() -> Void)?
    var actionLabel: String?
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SemanticColor.secondaryLabel)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            if let action, let actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.xs)
    }
}

// MARK: - HIG Icon Badge

struct HIGIconBadge: View {
    let systemName: String
    var color: Color = .accentColor
    var size: CGFloat = 32
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - HIG Status Badge

struct HIGStatusBadge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, DesignTokens.Spacing.xxs)
        .background(Capsule().fill(color.opacity(0.12)))
    }
}

// MARK: - HIG Divider

struct HIGDivider: View {
    var inset: CGFloat = 0
    var body: some View {
        SemanticColor.separator.frame(height: 0.5).padding(.leading, inset)
    }
}

// MARK: - HIG Empty State

struct HIGEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(SemanticColor.quaternarySystemFill)
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(SemanticColor.tertiaryLabel)
            }
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundStyle(SemanticColor.label)
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(SemanticColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            if let action, let actionLabel {
                Button(action: action) { Text(actionLabel) }
                    .buttonStyle(.higPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - HIG Loading View

struct HIGLoadingView: View {
    var message: String = "Laden..."
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            InlineSkeletonLoader(size: 28, tint: Color.accentColor.opacity(0.6))
            SkeletonShape(width: CGFloat(message.count * 8), height: 16, cornerRadius: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxl)
        .accessibilityLabel(message)
    }
}
