//
//  RefreshTimestamp.swift
//  Linio
//
//  Zeigt Zeitstempel der letzten Aktualisierung an
//

import SwiftUI
import Combine

// MARK: - Refresh Timestamp View

struct RefreshTimestampView: View {
    let lastRefresh: Date?
    let isRefreshing: Bool
    
    private let formatter = DateFormattingHelper.shared
    
    var body: some View {
        HStack(spacing: 6) {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Aktualisiere...")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            } else if let lastRefresh {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.mutedSoft)
                Text(relativeTimeString(for: lastRefresh))
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private func relativeTimeString(for date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        
        if seconds < 10 {
            return "Gerade aktualisiert"
        } else if seconds < 60 {
            return "Vor \(seconds) Sek."
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "Vor \(minutes) Min."
        } else {
            return "Zuletzt: \(formatter.formatTimeFromDate(date))"
        }
    }
    
    private var accessibilityLabel: String {
        if isRefreshing {
            return "Daten werden aktualisiert"
        } else if let lastRefresh {
            return "Zuletzt aktualisiert: \(relativeTimeString(for: lastRefresh))"
        }
        return ""
    }
}

// MARK: - Refreshable Modifier with Timestamp & Haptics

struct RefreshableWithFeedback: ViewModifier {
    @Binding var lastRefresh: Date?
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                await action()
                lastRefresh = Date()
                HapticHelper.success()
            }
    }
}

extension View {
    /// Pull-to-Refresh mit automatischem Zeitstempel und Haptic Feedback
    func refreshableWithFeedback(
        lastRefresh: Binding<Date?>,
        action: @escaping () async -> Void
    ) -> some View {
        modifier(RefreshableWithFeedback(lastRefresh: lastRefresh, action: action))
    }
}

// MARK: - Auto-Updating Timestamp

/// Performance-optimierte Version: Timer startet nur wenn View sichtbar ist
/// und stoppt automatisch beim Verschwinden der View.
struct AutoUpdatingTimestamp: View {
    let date: Date?
    
    @State private var refreshTrigger = false
    @State private var timerSubscription: AnyCancellable?
    
    var body: some View {
        RefreshTimestampView(lastRefresh: date, isRefreshing: false)
            .id(refreshTrigger)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
    }
    
    private func startTimer() {
        // Nur starten wenn noch nicht aktiv
        guard timerSubscription == nil else { return }
        timerSubscription = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                refreshTrigger.toggle()
            }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
}

// MARK: - Previews

#Preview("Refresh Timestamps") {
    VStack(spacing: 20) {
        RefreshTimestampView(lastRefresh: Date(), isRefreshing: false)
        RefreshTimestampView(lastRefresh: Date().addingTimeInterval(-45), isRefreshing: false)
        RefreshTimestampView(lastRefresh: Date().addingTimeInterval(-180), isRefreshing: false)
        RefreshTimestampView(lastRefresh: Date().addingTimeInterval(-3700), isRefreshing: false)
        RefreshTimestampView(lastRefresh: nil, isRefreshing: true)
    }
    .padding()
    .background(AppTheme.canvas)
}
