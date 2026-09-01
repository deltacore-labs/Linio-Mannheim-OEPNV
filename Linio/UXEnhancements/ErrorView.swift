//
//  ErrorView.swift
//  Linio
//
//  Einheitliche UI-Komponente für Fehleranzeigen.
//

import SwiftUI

/// Kompakte Fehlermeldung als Banner
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
        HStack(spacing: 12) {
            Image(systemName: error.iconName)
                .font(.title3)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.shortDescription)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                
                if let desc = error.errorDescription, desc != error.shortDescription {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if error.isRetryable, let retry = onRetry {
                Button(action: retry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.white.opacity(0.2), in: Circle())
                }
            }
            
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.gradient)
        )
        .padding(.horizontal)
    }
}

/// Vollständige Fehlerseite (für leere Zustände)
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
        } description: {
            if let desc = error.errorDescription {
                Text(desc)
            }
        } actions: {
            if error.isRetryable, let retry = onRetry {
                Button("Erneut versuchen", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// Inline-Fehlermeldung (für Formulare etc.)
struct ErrorInlineView: View {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    init(error: NetworkError) {
        self.message = error.shortDescription
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
