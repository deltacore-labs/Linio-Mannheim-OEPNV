//
//  ErrorView.swift
//  Linio
//
//  Einheitliche UI-Komponente für Fehleranzeigen.
//  Apple HIG-konform mit semantischen Farben
//

import SwiftUI

/// Kompakte Fehlermeldung als Banner (Apple HIG)
struct ErrorBannerView: View {
    let error: NetworkError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(error: NetworkError, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: error.iconName)
                .font(Typography.title3)
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.shortDescription)
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                
                if let desc = error.errorDescription, desc != error.shortDescription {
                    Text(desc)
                        .font(Typography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if error.isRetryable, let retry = onRetry {
                Button(action: {
                    HapticHelper.impact(.light)
                    retry()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .accessibleButton(label: "Erneut versuchen")
            }
            
            if let dismiss = onDismiss {
                Button(action: {
                    HapticHelper.softTap()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                }
                .accessibleButton(label: "Schließen")
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                .fill(SemanticColor.systemRed.gradient)
        )
        .padding(.horizontal, DesignTokens.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fehler: \(error.shortDescription)")
    }
}

/// Vollständige Fehlerseite (Apple HIG ContentUnavailableView)
struct ErrorPageView: View {
    let error: NetworkError
    let onRetry: (() -> Void)?
    
    init(error: NetworkError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }
    
    var body: some View {
        ContentUnavailableView {
            Label(error.shortDescription, systemImage: error.iconName)
                .symbolRenderingMode(.hierarchical)
        } description: {
            if let desc = error.errorDescription {
                Text(desc)
            }
        } actions: {
            if error.isRetryable, let retry = onRetry {
                Button {
                    HapticHelper.impact(.medium)
                    retry()
                } label: {
                    Text("Erneut versuchen")
                }
                .buttonStyle(.borderedProminent)
                .accessibleButton(label: "Erneut versuchen", hint: "Versucht die Aktion nochmals")
            }
        }
    }
}

/// Inline-Fehlermeldung (für Formulare etc.) - Apple HIG
struct ErrorInlineView: View {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    init(error: NetworkError) {
        self.message = error.shortDescription
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(SemanticColor.systemRed)
                .symbolRenderingMode(.hierarchical)
            Text(message)
                .font(Typography.caption)
                .foregroundStyle(SemanticColor.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fehler: \(message)")
    }
}

// MARK: - Preview

#Preview("Error Views") {
    VStack(spacing: 20) {
        ErrorBannerView(error: .noInternet, onRetry: {}, onDismiss: {})
        ErrorBannerView(error: .serverError, onRetry: {})
    }
    .padding()
}
