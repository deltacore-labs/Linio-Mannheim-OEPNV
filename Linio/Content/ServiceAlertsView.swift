//
//  ServiceAlertsView.swift
//  Linio
//
//  Zeigt Störungsmeldungen und Service-Alerts an
//

import SwiftUI

struct ServiceAlertsView: View {
    @ObservedObject var alertsManager: ServiceAlertsManager
    @ObservedObject var authService: AuthService
    @State private var selectedCategory: AlertCategory?
    @State private var expandedAlertID: String?
    
    var body: some View {
        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            
            if alertsManager.isLoading && alertsManager.alerts.isEmpty {
                // Skeleton das zum "Alles läuft!" EmptyState passt
                ServiceAlertsSkeleton()
            } else if filteredAlerts.isEmpty {
                emptyStateView
            } else {
                alertsList
            }
        }
        .navigationTitle("Störungen")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            if let token = authService.accessToken {
                await alertsManager.fetchAlerts(accessToken: token, forceRefresh: true)
            }
        }
        .task {
            if let token = authService.accessToken {
                await alertsManager.fetchAlerts(accessToken: token)
            }
        }
    }
    
    private var filteredAlerts: [ServiceAlert] {
        let active = alertsManager.activeAlerts
        if let category = selectedCategory {
            return active.filter { $0.category == category }
        }
        return active
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            EmptyStateView.noAlerts()
            
            if let lastUpdate = alertsManager.lastUpdate {
                Text("Stand: \(lastUpdate, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
    
    private var alertsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                categoryFilterBar
                ForEach(filteredAlerts) { alert in
                    AlertCard(alert: alert, isExpanded: expandedAlertID == alert.id) {
                        withAnimation(.spring(response: 0.3)) {
                            expandedAlertID = expandedAlertID == alert.id ? nil : alert.id
                        }
                    }
                }
            }.padding()
        }
    }
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Alle", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(AlertCategory.allCases, id: \.self) { category in
                    let count = alertsManager.activeAlerts.filter { $0.category == category }.count
                    if count > 0 {
                        FilterChip(title: category.displayName, count: count, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
            }.padding(.horizontal, 4)
        }.padding(.bottom, 8)
    }
}

// MARK: - AlertCard

private struct AlertCard: View {
    let alert: ServiceAlert
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: alert.severity.icon).font(.title2).foregroundStyle(alert.severity.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title).font(.headline).lineLimit(isExpanded ? nil : 2)
                    HStack(spacing: 8) {
                        Label(alert.category.displayName, systemImage: alert.category.icon).font(.caption).foregroundStyle(.secondary)
                        Text("•").foregroundStyle(.tertiary)
                        Text(alert.formattedValidityPeriod).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !alert.description.isEmpty {
                        Text(alert.description).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if !alert.affectedLines.isEmpty {
                        HStack(spacing: 8) {
                            Text("Betroffene Linien:").font(.caption.weight(.medium))
                            ForEach(alert.affectedLines.prefix(5), id: \.self) { line in
                                Text(line).font(.caption.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(AppTheme.primaryColor.opacity(0.15)).foregroundStyle(AppTheme.primaryColor).clipShape(Capsule())
                            }
                        }
                    }
                }.transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            LiquidGlassBackground(cornerRadius: 16, intensity: .standard)
        )
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(alert.severity.color.opacity(0.3), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if let count = count { Text("(\(count))").fontWeight(.medium) }
            }
            .font(.subheadline).padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected ? AppTheme.primaryColor : AppTheme.surfaceCard)
            .foregroundStyle(isSelected ? .white : AppTheme.ink)
            .clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}

// MARK: - Compact Alert Banner

struct ServiceAlertBanner: View {
    let alerts: [ServiceAlert]
    var onTap: (() -> Void)?
    
    var body: some View {
        if let mostSevere = alerts.sorted(by: { $0.severity.sortOrder < $1.severity.sortOrder }).first {
            Button { onTap?() } label: {
                HStack(spacing: 10) {
                    Image(systemName: mostSevere.severity.icon).foregroundStyle(mostSevere.severity.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mostSevere.title).font(.subheadline.weight(.medium)).lineLimit(1)
                        if alerts.count > 1 {
                            Text("+\(alerts.count - 1) weitere Meldungen").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(mostSevere.severity.color.opacity(0.1)))
            }.buttonStyle(.plain)
        }
    }
}
