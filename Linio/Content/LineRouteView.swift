//
//  LineRouteView.swift
//  Linio
//
//  Zeigt den vollständigen Linienverlauf einer Fahrt von Start bis Ende
//

import SwiftUI

struct LineRouteView: View {
    let lineName: String
    let direction: String
    let stops: [RouteStop]
    let currentStopIndex: Int?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.canvas.ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                                RouteStopRow(stop: stop, index: index, totalStops: stops.count,
                                           isCurrentStop: index == currentStopIndex,
                                           isPastStop: currentStopIndex.map { index < $0 } ?? false)
                                .id(index)
                            }
                        }.padding()
                    }
                    .onAppear {
                        if let current = currentStopIndex {
                            withAnimation { proxy.scrollTo(max(0, current - 1), anchor: .top) }
                        }
                    }
                }
            }
            .navigationTitle(lineName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(lineName).font(.headline)
                        Text("→ \(direction)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.font(.system(size: 15, weight: .medium))
                }
            }
        }
    }
}

// MARK: - RouteStop Model

struct RouteStop: Identifiable {
    let id = UUID()
    let name: String
    let scheduledTime: String?
    let estimatedTime: String?
    let platform: String?
    
    var delayMinutes: Int? {
        guard let scheduled = scheduledTime, let estimated = estimatedTime else { return nil }
        return DateFormattingHelper.shared.delayValue(timetabled: scheduled, estimated: estimated)
    }
}

// MARK: - RouteStopRow

private struct RouteStopRow: View {
    let stop: RouteStop
    let index: Int
    let totalStops: Int
    let isCurrentStop: Bool
    let isPastStop: Bool
    
    private var isFirst: Bool { index == 0 }
    private var isLast: Bool { index == totalStops - 1 }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Rectangle().fill(isFirst ? .clear : (isPastStop ? AppTheme.ink.opacity(0.2) : AppTheme.primaryColor))
                    .frame(width: 3, height: 20)
                Circle().fill(stopCircleColor)
                    .frame(width: isCurrentStop ? 16 : (isFirst || isLast ? 14 : 10),
                           height: isCurrentStop ? 16 : (isFirst || isLast ? 14 : 10))
                    .overlay { if isCurrentStop { Circle().stroke(AppTheme.primaryColor.opacity(0.3), lineWidth: 4) } }
                Rectangle().fill(isLast ? .clear : (isPastStop ? AppTheme.ink.opacity(0.2) : AppTheme.primaryColor))
                    .frame(width: 3, height: 40)
            }.frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stop.name)
                        .font(isFirst || isLast || isCurrentStop ? .headline : .subheadline)
                        .foregroundStyle(isPastStop && !isCurrentStop ? .secondary : .primary)
                    Spacer()
                    if let platform = stop.platform {
                        Text(platform).font(.caption2.weight(.medium)).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(AppTheme.ink.opacity(0.1)).clipShape(Capsule())
                    }
                }
                if let scheduled = stop.scheduledTime {
                    HStack(spacing: 8) {
                        Text(DateFormattingHelper.shared.formatTime(scheduled))
                            .font(.subheadline.monospacedDigit()).foregroundStyle(isPastStop ? .tertiary : .secondary)
                        if let delay = stop.delayMinutes, delay > 0 {
                            Text("+\(delay) min").font(.caption.weight(.medium)).foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(delay >= 5 ? Color.red : Color.orange).clipShape(Capsule())
                        }
                    }
                }
            }.padding(.vertical, 8)
        }
        .padding(.horizontal, 4)
        .background(isCurrentStop ? RoundedRectangle(cornerRadius: 12).fill(AppTheme.primaryColor.opacity(0.1)).padding(.horizontal, -8) : nil)
    }
    
    private var stopCircleColor: Color {
        if isCurrentStop { return AppTheme.primaryColor }
        if isPastStop { return AppTheme.ink.opacity(0.3) }
        if isFirst || isLast { return AppTheme.primaryColor }
        return AppTheme.primaryColor.opacity(0.6)
    }
}

// MARK: - Extension: Create from Departure

extension LineRouteView {
    static func from(departure: Departure) -> LineRouteView {
        var stops: [RouteStop] = []
        if let boardName = departure.boardStopName {
            stops.append(RouteStop(name: boardName, scheduledTime: departure.scheduledDeparture,
                                   estimatedTime: departure.estimatedDeparture, platform: departure.quayLetter))
        }
        for intermediate in departure.intermediateStops {
            stops.append(RouteStop(name: intermediate.name, scheduledTime: intermediate.scheduledTime,
                                   estimatedTime: intermediate.estimatedTime, platform: nil))
        }
        if let final = departure.finalStop {
            stops.append(RouteStop(name: final.name, scheduledTime: final.scheduledTime,
                                   estimatedTime: final.estimatedTime, platform: nil))
        }
        return LineRouteView(lineName: departure.lineName, direction: departure.direction, stops: stops, currentStopIndex: 0)
    }
}
