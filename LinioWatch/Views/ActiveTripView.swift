import SwiftUI
import Combine

struct ActiveTripView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @StateObject private var hapticManager = WatchHapticManager.shared
    @State private var showingDetails = false

    var body: some View {
        NavigationStack {
            Group {
                if let trip = dataManager.activeTrip {
                    TripTrackingView(trip: trip, showingDetails: $showingDetails)
                } else {
                    NoActiveTripView()
                }
            }
            .navigationTitle("Aktive Fahrt".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Aktive Fahrt vorhanden

private struct TripTrackingView: View {
    let trip: WidgetTripData
    @Binding var showingDetails: Bool
    @State private var now = Date()
    @State private var animateProgress = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var phase: TripPhase { WatchDateHelper.phase(for: trip) }
    private var firstLeg: WidgetTripLegData? { trip.legs.first(where: { $0.isTimedLeg }) }
    
    private var progressValue: Double {
        guard let start = WatchDateHelper.parse(trip.startTime),
              let end = WatchDateHelper.parse(trip.endTime) else { return 0 }
        let total = end.timeIntervalSince(start)
        let elapsed = Date().timeIntervalSince(start)
        return min(max(elapsed / total, 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Progress Bar (nur während der Fahrt)
                if phase == .duringJourney {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.green)
                                .frame(width: geo.size.width * (animateProgress ? progressValue : 0), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .onAppear { withAnimation(.easeOut(duration: 0.8)) { animateProgress = true } }
                }
                
                // Linie + Phase
                HStack {
                    if let leg = firstLeg {
                        LineBadgeView(serviceName: leg.serviceName, serviceType: leg.serviceType)
                    }
                    Spacer()
                    PhaseIndicatorView(phase: phase)
                }

                // Abfahrt / Ankunft
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ab".localized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(WatchDateHelper.formatTime(trip.startTime))
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(phase == .beforeDeparture ? .orange : .primary)
                    }

                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("An".localized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(WatchDateHelper.formatTime(trip.endTime))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(phase == .arrived ? .green : .secondary)
                    }
                }

                // Countdown / Status
                CountdownView(trip: trip, phase: phase, now: now)

                Divider()

                // Route (kompakter)
                VStack(alignment: .leading, spacing: 4) {
                    RouteStopRow(name: trip.startStation, isStart: true, isActive: phase == .beforeDeparture)

                    if trip.interchanges > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                            Text("\(trip.interchanges) Umstieg\(trip.interchanges > 1 ? "e" : "")".localized)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        .padding(.leading, 10)
                    }

                    RouteStopRow(name: trip.endStation, isStart: false, isActive: phase == .arrived)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Aktive Fahrt".localized)
        .onReceive(timer) { now = $0 }
    }
}

// MARK: - Countdown / Status Block

private struct CountdownView: View {
    let trip: WidgetTripData
    let phase: TripPhase
    let now: Date

    var body: some View {
        switch phase {
        case .beforeDeparture:
            if let mins = WatchDateHelper.minutesUntil(trip.startTime) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge")
                        .foregroundColor(.cyan)
                    if mins == 0 {
                        Text("Jetzt abfahren")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        Text("in \(mins) Min")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                }
            }

        case .duringJourney:
            HStack(spacing: 6) {
                Circle().fill(.green).frame(width: 6, height: 6)
                Text("Unterwegs".localized)
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                if let mins = WatchDateHelper.minutesUntil(trip.endTime) {
                    Text("noch \(mins) Min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        case .arrived:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Angekommen".localized)
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Keine aktive Fahrt

private struct NoActiveTripView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tram")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("Keine aktive Fahrt".localized)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Starte eine Live Activity\nauf dem iPhone".localized)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Wiederverwendbare Subviews

struct LineBadgeView: View {
    let serviceName: String?
    let serviceType: String?

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: WatchStyleHelper.icon(serviceType: serviceType, serviceName: serviceName))
                .font(.system(size: 9, weight: .bold))
            Text(WatchStyleHelper.shortName(serviceName))
                .font(.system(size: 11, weight: .heavy, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(WatchStyleHelper.colorValue(serviceType: serviceType, serviceName: serviceName))
        )
    }
}

private struct PhaseIndicatorView: View {
    let phase: TripPhase

    var body: some View {
        switch phase {
        case .beforeDeparture:
            Label("Bald".localized, systemImage: "clock.fill")
                .font(.caption2.bold())
                .foregroundColor(.cyan)
        case .duringJourney:
            Label("Fährt".localized, systemImage: "location.fill")
                .font(.caption2.bold())
                .foregroundColor(.green)
        case .arrived:
            Label("Da".localized, systemImage: "checkmark.circle.fill")
                .font(.caption2.bold())
                .foregroundColor(.green)
        }
    }
}

private struct RouteStopRow: View {
    let name: String
    let isStart: Bool
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isStart ? Color.green : (isActive ? Color.green : Color.secondary))
                    .frame(width: 6, height: 6)
                if isActive {
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .frame(width: 10, height: 10)
                }
            }
            Text(name)
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .green : (isStart ? .primary : .secondary))
                .lineLimit(1)
        }
    }
}

#if DEBUG
#Preview("Aktive Fahrt") {
    let dm = WatchDataManager()
    dm.activeTrip = WatchDemoData.activeTrip
    return ActiveTripView()
        .environmentObject(dm)
}

#Preview("Keine Fahrt") {
    let dm = WatchDataManager()
    return ActiveTripView()
        .environmentObject(dm)
}
#endif
