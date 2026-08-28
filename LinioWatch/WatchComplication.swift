// WatchComplication.swift
// WidgetKit-basierte Complication für das Watch-Zifferblatt

import WidgetKit
import SwiftUI

// MARK: - Complication Entry

struct DepartureEntry: TimelineEntry {
    let date: Date
    let lineName: String?
    let destination: String?
    let departureTime: String?
    let minutesUntil: Int?
    let hasActiveTrip: Bool
    
    static var placeholder: DepartureEntry {
        DepartureEntry(
            date: Date(),
            lineName: "5",
            destination: "HD Bismarckplatz",
            departureTime: "14:32",
            minutesUntil: 8,
            hasActiveTrip: true
        )
    }
    
    static var empty: DepartureEntry {
        DepartureEntry(
            date: Date(),
            lineName: nil,
            destination: nil,
            departureTime: nil,
            minutesUntil: nil,
            hasActiveTrip: false
        )
    }
}

// MARK: - Timeline Provider

struct DepartureTimelineProvider: TimelineProvider {
    private let appGroupID = "group.com.stefanfriedrich.rnvapp"
    
    func placeholder(in context: Context) -> DepartureEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DepartureEntry) -> Void) {
        completion(context.isPreview ? .placeholder : loadCurrentEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DepartureEntry>) -> Void) {
        let entry = loadCurrentEntry()
        
        // Aktualisiere alle 5 Minuten oder wenn sich die Zeit ändert
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCurrentEntry() -> DepartureEntry {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "savedTripData") else {
            return .empty
        }
        
        let activeIDs = Set(defaults.stringArray(forKey: "activeTrips") ?? [])
        guard !activeIDs.isEmpty else { return .empty }
        
        let now = Date()
        let allTrips = (try? JSONDecoder().decode([WidgetTripData].self, from: data)) ?? []
        
        guard let trip = allTrips
            .filter({ activeIDs.contains($0.id) })
            .filter({ trip in
                guard let end = WatchDateHelper.parse(trip.endTime) else { return false }
                return end > now
            })
            .sorted(by: {
                let a = WatchDateHelper.parse($0.startTime) ?? .distantFuture
                let b = WatchDateHelper.parse($1.startTime) ?? .distantFuture
                return a < b
            })
            .first else { return .empty }
        
        let firstLeg = trip.legs.first(where: { $0.isTimedLeg })
        let lineName = WatchStyleHelper.shortName(firstLeg?.serviceName)
        let depTime = WatchDateHelper.formatTime(trip.startTime)
        let mins = WatchDateHelper.minutesUntil(trip.startTime)
        
        return DepartureEntry(
            date: now,
            lineName: lineName,
            destination: trip.endStation,
            departureTime: depTime,
            minutesUntil: mins,
            hasActiveTrip: true
        )
    }
}

// MARK: - Complication Views

struct ComplicationCircularView: View {
    let entry: DepartureEntry
    
    var body: some View {
        if entry.hasActiveTrip, let mins = entry.minutesUntil {
            ZStack {
                AccessoryWidgetBackground()
                
                // Fortschrittsring (basierend auf Zeit, max 60 min)
                Circle()
                    .trim(from: 0, to: min(Double(mins) / 60.0, 1.0))
                    .stroke(
                        mins <= 2 ? Color.orange : Color.green,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(2)
                
                VStack(spacing: -2) {
                    if let line = entry.lineName {
                        Text(line)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    Text("\(mins)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(mins <= 2 ? .orange : .primary)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: "tram")
                        .font(.system(size: 16))
                    Text("Linio")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ComplicationRectangularView: View {
    let entry: DepartureEntry
    
    var body: some View {
        if entry.hasActiveTrip {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    if let line = entry.lineName {
                        HStack(spacing: 3) {
                            Image(systemName: "tram.fill")
                                .font(.system(size: 10))
                            Text(line)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    if let dest = entry.destination {
                        Text(dest)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let mins = entry.minutesUntil {
                    VStack(alignment: .trailing) {
                        Text("\(mins)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("min")
                            .font(.system(size: 9))
                    }
                }
            }
        } else {
            HStack {
                Image(systemName: "tram")
                Text("Keine Fahrt")
                    .font(.caption)
            }
        }
    }
}

struct ComplicationInlineView: View {
    let entry: DepartureEntry
    
    var body: some View {
        if entry.hasActiveTrip, let line = entry.lineName, let mins = entry.minutesUntil {
            Label("\(line) in \(mins) min", systemImage: "tram.fill")
        } else {
            Label("Linio", systemImage: "tram")
        }
    }
}

struct ComplicationCornerView: View {
    let entry: DepartureEntry
    
    var body: some View {
        if entry.hasActiveTrip, let mins = entry.minutesUntil {
            Text("\(mins)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .widgetLabel {
                    Label(entry.lineName ?? "Bahn", systemImage: "tram.fill")
                }
        } else {
            Image(systemName: "tram")
                .widgetLabel("Linio")
        }
    }
}

// MARK: - Widget Definition

struct LinioWatchComplication: Widget {
    let kind: String = "LinioWatchComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DepartureTimelineProvider()) { entry in
            ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Nächste Abfahrt")
        .description("Zeigt die nächste geplante Abfahrt auf dem Zifferblatt.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct ComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DepartureEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ComplicationCircularView(entry: entry)
        case .accessoryRectangular:
            ComplicationRectangularView(entry: entry)
        case .accessoryInline:
            ComplicationInlineView(entry: entry)
        case .accessoryCorner:
            ComplicationCornerView(entry: entry)
        default:
            ComplicationCircularView(entry: entry)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Circular", as: .accessoryCircular) {
    LinioWatchComplication()
} timeline: {
    DepartureEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LinioWatchComplication()
} timeline: {
    DepartureEntry.placeholder
}

#Preview("Inline", as: .accessoryInline) {
    LinioWatchComplication()
} timeline: {
    DepartureEntry.placeholder
}

#Preview("Corner", as: .accessoryCorner) {
    LinioWatchComplication()
} timeline: {
    DepartureEntry.placeholder
}
#endif
