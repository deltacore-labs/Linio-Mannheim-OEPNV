//
//  EmptyStateView.swift
//  Linio
//
//  Wiederverwendbare Empty State Komponente mit Call-to-Actions
//  Apple HIG-konform: ContentUnavailableView-Stil
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let ctaTitle: String?
    let ctaIcon: String?
    let ctaAction: (() -> Void)?
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        ctaTitle: String? = nil,
        ctaIcon: String? = nil,
        ctaAction: (() -> Void)? = nil,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.ctaIcon = ctaIcon
        self.ctaAction = ctaAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Icon mit Hintergrund (Apple HIG Style)
            ZStack {
                Circle()
                    .fill(SemanticColor.tertiarySystemFill)
                    .frame(width: 88, height: 88)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(SemanticColor.secondaryLabel)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)
            
            // Text-Inhalt (HIG Typography)
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(Typography.title3.weight(.semibold))
                    .foregroundStyle(SemanticColor.label)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(Typography.subheadline)
                    .foregroundStyle(SemanticColor.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            
            // CTA Buttons (HIG Button Styles)
            if let ctaTitle, let ctaAction {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Button {
                        HapticHelper.impact(.medium)
                        ctaAction()
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            if let ctaIcon {
                                Image(systemName: ctaIcon)
                                    .font(.body.weight(.semibold))
                            }
                            Text(ctaTitle)
                                .font(.body.weight(.semibold))
                        }
                    }
                    .buttonStyle(.higPrimary)
                    .accessibleButton(label: ctaTitle, hint: "Tippen zum Ausführen")
                    
                    if let secondaryTitle, let secondaryAction {
                        Button {
                            HapticHelper.softTap()
                            secondaryAction()
                        } label: {
                            Text(secondaryTitle)
                                .font(Typography.subheadline)
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Keine Verbindungen - Aufforderung zur Suche
    static func noConnections(onSearch: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "tram.fill",
            title: "Wohin möchtest du fahren?",
            message: "Wähle Start und Ziel oben, um passende Verbindungen zu finden.",
            ctaTitle: "Haltestelle wählen",
            ctaIcon: "magnifyingglass",
            ctaAction: onSearch
        )
    }
    
    /// Keine Störungen
    static func noAlerts() -> EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle.fill",
            title: "Alles läuft!",
            message: "Momentan gibt es keine Störungen oder Verspätungen im rnv-Netz."
        )
    }
}

// MARK: - Previews

#Preview("No Connections") {
    EmptyStateView.noConnections { }
        .background(AppTheme.canvas)
}

#Preview("No Alerts") {
    EmptyStateView.noAlerts()
        .background(AppTheme.canvas)
}
