//
//  OccupancyTrendView.swift
//  Linio
//
//  Zeigt historische Auslastungstrends für eine Linie
//

import SwiftUI

struct OccupancyTrendView: View {
    let lineName: String
    let direction: String
    let stationName: String
    
    // Performance: @StateObject für Singleton
    @StateObject var trendManager = OccupancyTrendManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.canvas.ignoresSafeArea()
                
                if let currentTrend = trendManager.trend(forLine: lineName, direction: direction, stationName: stationName) {
                    ScrollView {
                        VStack(spacing: 24) {
                            currentTrendCard(currentTrend)
                            weekOverviewSection
                            dataInfoSection
                        }.padding()
                    }
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Auslastungs-Trend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.font(.system(size: 15, weight: .medium))
                }
            }
        }
    }
    
    private func currentTrendCard(_ trend: OccupancyTrend) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktuelle Prognose").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(trend.dayName), \(trend.timeRange)").font(.headline)
                }
                Spacer()
                occupancyBadge(trend.averageOccupancy, large: true)
            }
            Divider()
            HStack {
                Label(trend.confidence.displayText, systemImage: "chart.bar.fill").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(trend.sampleCount) Datenpunkte").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.surfaceCard))
    }
    
    private var weekOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wochenübersicht").font(.headline)
            VStack(spacing: 8) {
                ForEach(2...6, id: \.self) { day in dayRow(dayOfWeek: day) }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.surfaceCard))
    }
    
    private func dayRow(dayOfWeek: Int) -> some View {
        let days = ["", "So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"]
        let morningTrend = trendManager.trend(forLine: lineName, direction: direction, stationName: stationName,
                                              at: dateFor(dayOfWeek: dayOfWeek, hour: 8))
        let eveningTrend = trendManager.trend(forLine: lineName, direction: direction, stationName: stationName,
                                              at: dateFor(dayOfWeek: dayOfWeek, hour: 17))
        return HStack {
            Text(days[dayOfWeek]).font(.subheadline.weight(.medium)).frame(width: 30, alignment: .leading)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("🌅").font(.caption2)
                    if let t = morningTrend { occupancyBadge(t.averageOccupancy, large: false) }
                    else { Text("–").font(.caption).foregroundStyle(.tertiary) }
                }
                HStack(spacing: 4) {
                    Text("🌆").font(.caption2)
                    if let t = eveningTrend { occupancyBadge(t.averageOccupancy, large: false) }
                    else { Text("–").font(.caption).foregroundStyle(.tertiary) }
                }
            }
            Spacer()
        }.padding(.vertical, 4)
    }
    
    private func dateFor(dayOfWeek: Int, hour: Int) -> Date {
        var components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = dayOfWeek
        components.hour = hour
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private var dataInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("So funktioniert's", systemImage: "lightbulb.fill").font(.subheadline.weight(.medium)).foregroundStyle(.orange)
            Text("Die Prognose basiert auf deinen bisherigen Fahrten.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.orange.opacity(0.1)))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("Noch keine Daten").font(.title3.weight(.semibold))
            Text("Nutze diese Verbindung ein paar Mal,\num Auslastungstrends zu sehen.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding()
    }
    
    private func occupancyBadge(_ level: OccupancyLevel, large: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(i < level.filledCount ? level.color : level.color.opacity(0.2))
                    .frame(width: large ? 10 : 6, height: large ? 10 : 6)
            }
            if large { Text(level.displayText).font(.subheadline.weight(.medium)).foregroundStyle(level.color).padding(.leading, 4) }
        }
    }
}
