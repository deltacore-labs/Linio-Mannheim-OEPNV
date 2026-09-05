//
//  WalletDebugLogsView.swift
//  Linio
//
//  Zeigt Wallet Debug-Logs für TestFlight-Nutzer an.
//

import SwiftUI

struct WalletDebugLogsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logs: [WalletDebugLogger.LogEntry] = []
    @State private var filterLevel: WalletDebugLogger.LogEntry.LogLevel? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                
                if logs.isEmpty {
                    emptyState
                } else {
                    logsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Wallet Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    shareButton
                }
            }
        }
        .onAppear { loadLogs() }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Alle", isSelected: filterLevel == nil) {
                    filterLevel = nil
                    loadLogs()
                }
                FilterChip(title: "❌ Fehler", isSelected: filterLevel == .error) {
                    filterLevel = .error
                    loadLogs()
                }
                FilterChip(title: "⚠️ Warnung", isSelected: filterLevel == .warning) {
                    filterLevel = .warning
                    loadLogs()
                }
                FilterChip(title: "✅ Erfolg", isSelected: filterLevel == .success) {
                    filterLevel = .success
                    loadLogs()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private var logsList: some View {
        List {
            ForEach(logs) { entry in
                LogEntryRow(entry: entry)
            }
        }
        .listStyle(.plain)
        .refreshable { loadLogs() }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Keine Logs vorhanden")
                .font(.headline)
            Text("Versuche, ein Ticket zum Wallet hinzuzufügen, um Logs zu generieren.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var shareButton: some View {
        Button {
            let logText = WalletDebugLogger.shared.getLogsAsText()
            let av = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(av, animated: true)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    private func loadLogs() {
        let all = WalletDebugLogger.shared.getAllLogs()
        if let level = filterLevel {
            logs = all.filter { $0.level == level }.reversed()
        } else {
            logs = all.reversed()
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.purple : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

private struct LogEntryRow: View {
    let entry: WalletDebugLogger.LogEntry
    
    private var timeString: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: entry.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.rawValue)
                Text(entry.message)
                    .font(.body.monospaced())
                    .fontWeight(.medium)
                Spacer()
                Text(timeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if let details = entry.details {
                Text(details)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WalletDebugLogsView()
}
