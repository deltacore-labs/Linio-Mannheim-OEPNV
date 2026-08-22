//
//  EmptyStateView.swift
//  Linio
//
//  Wiederverwendbare Empty State Komponente mit Call-to-Actions
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
        VStack(spacing: 24) {
            // Icon mit Hintergrund
            ZStack {
                Circle()
                    .fill(AppTheme.surfaceStrong)
                    .frame(width: 88, height: 88)
                
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.mutedSoft)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityHidden(true)
            
            // Text-Inhalt
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 24)
            
            // CTA Buttons
            if let ctaTitle, let ctaAction {
                VStack(spacing: 12) {
                    Button {
                        HapticHelper.impact(.medium)
                        ctaAction()
                    } label: {
                        HStack(spacing: 8) {
                            if let ctaIcon {
                                Image(systemName: ctaIcon)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(ctaTitle)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityHint("Tippen zum Ausführen")
                    
                    if let secondaryTitle, let secondaryAction {
                        Button {
                            HapticHelper.softTap()
                            secondaryAction()
                        } label: {
                            Text(secondaryTitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primaryColor)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
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
    
    /// Keine geplanten Fahrten
    static func noPlannedTrips(onNewTrip: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "Keine geplanten Fahrten",
            message: "Starte eine Live Activity für deine nächste Verbindung, um sie hier zu verfolgen.",
            ctaTitle: "Verbindung suchen",
            ctaIcon: "magnifyingglass",
            ctaAction: onNewTrip
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
    
    /// Keine Suchergebnisse
    static func noSearchResults(query: String, onClear: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "Keine Ergebnisse",
            message: "Für \"\(query)\" wurden keine Haltestellen gefunden.",
            ctaTitle: "Suche löschen",
            ctaIcon: "xmark.circle",
            ctaAction: onClear
        )
    }
    
    /// Leeres Archiv
    static func noArchive() -> EmptyStateView {
        EmptyStateView(
            icon: "archivebox",
            title: "Archiv ist leer",
            message: "Abgeschlossene Fahrten werden hier für 7 Tage gespeichert."
        )
    }
    
    /// Offline-Zustand
    static func offline(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Keine Verbindung",
            message: "Prüfe deine Internetverbindung und versuche es erneut.",
            ctaTitle: "Erneut versuchen",
            ctaIcon: "arrow.clockwise",
            ctaAction: onRetry
        )
    }
}

// MARK: - Previews

#Preview("No Connections") {
    EmptyStateView.noConnections { }
        .background(AppTheme.canvas)
}

#Preview("No Planned Trips") {
    EmptyStateView.noPlannedTrips { }
        .background(AppTheme.canvas)
}

#Preview("No Alerts") {
    EmptyStateView.noAlerts()
        .background(AppTheme.canvas)
}
