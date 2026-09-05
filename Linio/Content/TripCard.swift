//
//  TripCard.swift
//  Linio
//

import Combine
import SwiftUI

struct TripCard: View {
    let trip: DetailedTrip

    private let formatter = DateFormattingHelper.shared

    @ScaledMetric(relativeTo: .title2) private var largeTimeSize: CGFloat = 22
    @ScaledMetric(relativeTo: .title3) private var smallTimeSize: CGFloat = 20

    private var isPast: Bool {
        guard let endDate = formatter.parseISO8601(trip.endTime) else { return false }
        return endDate < Date()
    }

    private var minutesUntilDeparture: Int? {
        let depTime = trip.legs.first(where: { $0.isTimedLeg })?.estimatedDepartureTime ?? trip.startTime
        guard let depDate = formatter.parseISO8601(depTime) else { return nil }
        let mins = Int(depDate.timeIntervalSince(Date()) / 60)
        return mins >= 0 ? mins : nil
    }

    private var primaryLineColor: Color {
        guard let firstLeg = trip.legs.first(where: { $0.isTimedLeg }) else {
            return Color.accentColor
        }
        return TransportIconHelper.getLineColor(for: firstLeg.serviceType, serviceName: firstLeg.serviceName)
    }

    private var departureDelay: Int? { getFirstLegDelay() }
    private var arrivalDelay: Int? { getLastLegDelay() }

    private var maxDelay: Int? {
        let m = max(departureDelay ?? 0, arrivalDelay ?? 0)
        return m > 0 ? m : nil
    }

    private var timedLegs: [TripLeg] {
        trip.legs.filter { $0.isTimedLeg }
    }

    private var worstOccupancy: OccupancyLevel {
        let levels = timedLegs.compactMap { $0.occupancy }.filter { $0 != .unknown }
        return levels.max(by: { $0.severityRank < $1.severityRank }) ?? .unknown
    }

    var body: some View {
        HStack(spacing: 0) {
            // Moderner vertikaler Akzent-Streifen
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: isPast 
                            ? [SemanticColor.separator, SemanticColor.separator]
                            : [primaryLineColor, primaryLineColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Obere Zeile: Zeit + Status
                HStack(alignment: .top, spacing: 12) {
                    timeRow
                    Spacer()
                    statusColumn
                }

                // Meta-Informationen
                metaRow
                
                // Transport-Linien
                transportLinesRow
            }
            .padding(.leading, DesignTokens.Spacing.sm)
            .padding(.trailing, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 4)
        }
        .background(
            ZStack {
                // Base: Eleganter Glasmorphismus-Hintergrund
                LiquidGlassBackground(
                    cornerRadius: DesignTokens.CornerRadius.large,
                    intensity: isPast ? .subtle : .standard
                )
                
                // Dezenter Farbverlauf für visuelle Tiefe
                if !isPast {
                    LinearGradient(
                        colors: [
                            primaryLineColor.opacity(0.04),
                            primaryLineColor.opacity(0.01),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                }
            }
            .opacity(isPast ? 0.55 : 1.0)
        )
        .overlay(
            // Dezenter Border mit Farbakzent
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .stroke(
                    LinearGradient(
                        colors: isPast 
                            ? [SemanticColor.separator.opacity(0.2), SemanticColor.separator.opacity(0.1)]
                            : [primaryLineColor.opacity(0.2), primaryLineColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .opacity(isPast ? 0.7 : 1.0)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Details anzeigen")
    }

    private var accessibilityDescription: String {
        let dep = formatter.formatTime(trip.startTime)
        let arr = formatter.formatTime(trip.endTime)
        let lineNames = timedLegs.compactMap { $0.serviceName }.joined(separator: ", ")
        var desc = "Verbindung \(dep) bis \(arr)"
        if !lineNames.isEmpty { desc += ", Linien: \(lineNames)" }
        if trip.interchanges == 0 { desc += ", direkt" } else { desc += ", \(trip.interchanges) Umstieg(e)" }
        if let delay = maxDelay, delay > 0 { desc += ", \(delay) Minuten Verspätung" }
        if isPast { desc += ", bereits abgefahren" }
        return desc
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack(spacing: 10) {
            timeView(scheduled: getFirstLegScheduledDeparture() ?? trip.startTime, estimated: getFirstLegEstimatedDeparture(), delay: departureDelay, isArrival: false)

            // Moderner Pfeil mit Animation-Potential
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.secondary.opacity(0.4), .secondary.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            timeView(scheduled: getLastLegScheduledArrival() ?? trip.endTime, estimated: getLastLegEstimatedArrival(), delay: arrivalDelay, isArrival: true)
        }
    }

    @ViewBuilder
    private func timeView(scheduled: String, estimated: String?, delay: Int?, isArrival: Bool) -> some View {
        if let delay = delay, delay > 0, let est = estimated {
            VStack(alignment: isArrival ? .trailing : .leading, spacing: 2) {
                Text(formatter.formatTime(scheduled))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
                    .strikethrough(true, color: .red.opacity(0.4))
                Text(formatter.formatTime(est))
                    .font(.system(size: smallTimeSize, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
            }
        } else {
            Text(formatter.formatTime(scheduled))
                .font(.system(size: largeTimeSize, weight: .bold, design: .rounded))
                .foregroundColor(isPast ? .secondary : .primary)
        }
    }

    // MARK: - Status Column

    @ViewBuilder
    private var statusColumn: some View {
        VStack(alignment: .trailing, spacing: 5) {
            if isPast {
                statusBadge(text: "Abgefahren", icon: "clock.badge.xmark", color: SemanticColor.secondaryLabel, bg: SemanticColor.tertiarySystemFill)
            } else if let mins = minutesUntilDeparture, mins <= 60 {
                statusBadge(
                    text: mins == 0 ? "Jetzt" : "in \(mins) Min",
                    icon: mins <= 5 ? "figure.run" : "timer",
                    color: mins <= 5 ? SemanticColor.systemRed : Color.accentColor,
                    bg: (mins <= 5 ? SemanticColor.systemRed : Color.accentColor).opacity(0.12)
                )
            }

            if let delay = maxDelay, delay >= 2 {
                statusBadge(
                    text: "+\(delay) Min",
                    icon: delay >= 5 ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark",
                    color: delay >= 5 ? .red : .orange,
                    bg: (delay >= 5 ? Color.red : Color.orange).opacity(0.12)
                )
            } else if !isPast {
                statusBadge(text: "Pünktlich", icon: "checkmark.circle.fill", color: .green, bg: Color.green.opacity(0.12))
            }

            let occ = worstOccupancy
            if occ != .unknown {
                statusBadge(
                    text: occ.displayText,
                    icon: occ.iconName,
                    color: occ.color,
                    bg: occ.color.opacity(0.12)
                )
            }
        }
    }

    @ViewBuilder
    private func statusBadge(text: String, icon: String, color: Color, bg: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(bg)
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Meta Row

    private var metaRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(formatter.calculateDuration(start: trip.startTime, end: trip.endTime))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("·")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.4))

            if trip.interchanges == 0 {
                HStack(spacing: 3) {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.system(size: 10))
                    Text("Direkt")
                        .font(.subheadline)
                }
                .foregroundColor(AppTheme.primaryColor)
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 10))
                    Text("\(trip.interchanges)× Umstieg")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Transport Lines

    private var transportLinesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(timedLegs.enumerated()), id: \.offset) { index, leg in
                    if leg.serviceName != nil {
                        lineBadge(leg: leg)
                        if index < timedLegs.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func lineBadge(leg: TripLeg) -> some View {
        let isSBahn = TransportIconHelper.isSBahnLine(serviceType: leg.serviceType, serviceName: leg.serviceName)
        let lineColor = TransportIconHelper.getLineColor(for: leg.serviceType, serviceName: leg.serviceName)
        let hasDelay = (getLegDelay(leg) ?? 0) > 0

        HStack(spacing: 4) {
            Image(systemName: TransportIconHelper.getTransportIcon(for: leg.serviceType, serviceName: leg.serviceName))
                .font(.system(size: isSBahn ? 14 : 10))
            Text(TransportIconHelper.getShortLineName(from: leg.serviceName))
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(isSBahn ? .green : .white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Group {
                if isSBahn {
                    Capsule()
                        .fill(AppTheme.surfaceStrong)
                        .overlay(Capsule().stroke(hasDelay ? Color.red : Color.green, lineWidth: 1.5))
                } else if hasDelay {
                    Capsule()
                        .fill(lineColor)
                        .overlay(Capsule().stroke(Color.red, lineWidth: 1.5))
                } else {
                    Capsule().fill(lineColor)
                }
            }
        )
    }

    // MARK: - Helpers

    private func getFirstLegDelay() -> Int? {
        guard let firstTimedLeg = trip.legs.first(where: { $0.isTimedLeg }),
              let scheduled = firstTimedLeg.departureTime,
              let estimated = firstTimedLeg.estimatedDepartureTime else { return nil }
        return formatter.calculateDelay(timetabled: scheduled, estimated: estimated)
    }

    private func getLastLegDelay() -> Int? {
        guard let lastTimedLeg = trip.legs.last(where: { $0.isTimedLeg }),
              let scheduled = lastTimedLeg.arrivalTime,
              let estimated = lastTimedLeg.estimatedArrivalTime else { return nil }
        return formatter.calculateDelay(timetabled: scheduled, estimated: estimated)
    }

    private func getFirstLegScheduledDeparture() -> String? {
        trip.legs.first(where: { $0.isTimedLeg })?.departureTime
    }

    private func getLastLegScheduledArrival() -> String? {
        trip.legs.last(where: { $0.isTimedLeg })?.arrivalTime
    }

    private func getFirstLegEstimatedDeparture() -> String? {
        trip.legs.first(where: { $0.isTimedLeg })?.estimatedDepartureTime
    }

    private func getLastLegEstimatedArrival() -> String? {
        trip.legs.last(where: { $0.isTimedLeg })?.estimatedArrivalTime
    }

    private func getLegDelay(_ leg: TripLeg) -> Int? {
        guard let scheduled = leg.departureTime, let estimated = leg.estimatedDepartureTime else { return nil }
        return formatter.calculateDelay(timetabled: scheduled, estimated: estimated)
    }
}


// MARK: - Swipeable Trip Card (iOS 26 Glass Style)

/// Eine TripCard mit modernem Swipe-Verhalten
/// - Swipe links → Live Activity starten (grün)
/// - Swipe rechts → Teilen (blau)
/// - Elegante Glasmorphismus-Buttons mit sanften Übergängen
/// - Professionelle Animationen passend zum Design-System
struct SwipeableTripCard: View {
    let trip: DetailedTrip
    let onTap: () -> Void
    let onLiveActivity: () -> Void
    let onShare: () -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    private let buttonWidth: CGFloat = 80
    private let snapThreshold: CGFloat = 45
    private let fullSwipeThreshold: CGFloat = 160
    
    /// Reveal-Progress (0-1) für Animationen
    private var revealProgress: CGFloat { min(abs(offsetX) / buttonWidth, 1.0) }
    
    /// Elastischer Progress für Bounce-Effekte
    private var elasticProgress: CGFloat {
        let base = revealProgress
        return base > 0.8 ? 0.8 + (base - 0.8) * 0.4 : base
    }
    
    var body: some View {
        ZStack {
            // Hintergrund-Layer für Swipe-Actions
            HStack(spacing: 0) {
                // Share Action Background (links)
                if offsetX > 0 {
                    shareActionView
                        .frame(width: max(0, offsetX + 16))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: DesignTokens.CornerRadius.large,
                                bottomLeadingRadius: DesignTokens.CornerRadius.large,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                        )
                }
                
                Spacer()
                
                // Live Action Background (rechts)
                if offsetX < 0 {
                    liveActionView
                        .frame(width: max(0, abs(offsetX) + 16))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: DesignTokens.CornerRadius.large,
                                topTrailingRadius: DesignTokens.CornerRadius.large
                            )
                        )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            
            // TripCard im Vordergrund
            TripCard(trip: trip)
                .offset(x: offsetX)
                .shadow(
                    color: Color.black.opacity(offsetX != 0 ? 0.08 : 0),
                    radius: 8,
                    x: offsetX > 0 ? 4 : (offsetX < 0 ? -4 : 0),
                    y: 0
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous))
        .simultaneousGesture(dragGesture)
        .onTapGesture { handleTap() }
        .accessibilityAction(named: "Teilen") { onShare() }
        .accessibilityAction(named: "Live Activity") { onLiveActivity() }
    }
    
    // MARK: - Share Action (Refined Glass Style)
    private var shareActionView: some View {
        Button { triggerShare() } label: {
            ZStack {
                SwipeActionBackground(tintColor: SemanticColor.systemBlue, revealProgress: elasticProgress, isActive: offsetX > snapThreshold)
                
                HStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [SemanticColor.systemBlue.opacity(0.35 * elasticProgress), .clear], center: .center, startRadius: 0, endRadius: 28))
                                .frame(width: 56, height: 56)
                            Circle()
                                .fill(colorScheme == .dark ? SemanticColor.systemBlue.opacity(0.2) : SemanticColor.systemBlue.opacity(0.12))
                                .frame(width: 42, height: 42)
                                .overlay(Circle().stroke(SemanticColor.systemBlue.opacity(0.3), lineWidth: 1))
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SemanticColor.systemBlue)
                                .scaleEffect(offsetX > 15 ? 1.0 : 0.6)
                                .opacity(offsetX > 10 ? 1 : 0)
                        }
                        Text("Teilen")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(SemanticColor.systemBlue)
                            .opacity(offsetX > 40 ? min(1, (offsetX - 40) / 25) : 0)
                    }
                    .padding(.trailing, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(RefinedSwipeButtonStyle())
        .animation(DesignTokens.Animation.spring, value: elasticProgress)
    }
    
    // MARK: - Live Action (Refined Glass Style)
    private var liveActionView: some View {
        Button { triggerLive() } label: {
            ZStack {
                SwipeActionBackground(tintColor: SemanticColor.systemGreen, revealProgress: elasticProgress, isActive: abs(offsetX) > snapThreshold)
                
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [SemanticColor.systemGreen.opacity(0.35 * elasticProgress), .clear], center: .center, startRadius: 0, endRadius: 28))
                                .frame(width: 56, height: 56)
                            Circle()
                                .fill(colorScheme == .dark ? SemanticColor.systemGreen.opacity(0.2) : SemanticColor.systemGreen.opacity(0.12))
                                .frame(width: 42, height: 42)
                                .overlay(Circle().stroke(SemanticColor.systemGreen.opacity(0.3), lineWidth: 1))
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SemanticColor.systemGreen)
                                .scaleEffect(offsetX < -15 ? 1.0 : 0.6)
                                .opacity(offsetX < -10 ? 1 : 0)
                                .symbolEffect(.pulse, options: .repeating.speed(1.5), value: offsetX < -fullSwipeThreshold * 0.6)
                        }
                        Text("Live")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(SemanticColor.systemGreen)
                            .opacity(offsetX < -40 ? min(1, (abs(offsetX) - 40) / 25) : 0)
                    }
                    .padding(.leading, 16)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(RefinedSwipeButtonStyle())
        .animation(DesignTokens.Animation.spring, value: elasticProgress)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { v in
                guard abs(v.translation.width) > abs(v.translation.height) * 1.5 else { return }
                let t = v.translation.width
                let maxOff = buttonWidth * 1.5
                // Rubber-band effect
                if abs(t) > maxOff {
                    let excess = abs(t) - maxOff
                    offsetX = (t > 0 ? 1 : -1) * (maxOff + excess * 0.3)
                } else {
                    offsetX = t
                }
            }
            .onEnded { v in
                let t = v.translation.width
                let vel = v.predictedEndTranslation.width - t
                
                // Full-swipe → sofortige Aktion
                if t < -fullSwipeThreshold || vel < -300 {
                    performFullSwipe(isLeft: true)
                } else if t > fullSwipeThreshold || vel > 300 {
                    performFullSwipe(isLeft: false)
                } else if abs(t) > snapThreshold {
                    // Snap open
                    snapOpen(toLeft: t < 0)
                } else {
                    snapClosed()
                }
            }
    }
    
    // MARK: - Snap Functions
    
    private func snapOpen(toLeft: Bool) {
        let target = toLeft ? -buttonWidth : buttonWidth
        withAnimation(reduceMotion ? .none : DesignTokens.Animation.spring) {
            offsetX = target
            isOpen = true
        }
        HapticHelper.softTap()
    }
    
    private func snapClosed() {
        withAnimation(reduceMotion ? .none : DesignTokens.Animation.spring) {
            offsetX = 0
            isOpen = false
        }
    }
    
    private func performFullSwipe(isLeft: Bool) {
        withAnimation(DesignTokens.Animation.bounce) {
            offsetX = isLeft ? -400 : 400
        }
        HapticHelper.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isLeft ? onLiveActivity() : onShare()
            snapClosed()
        }
    }
    
    // MARK: - Tap & Trigger
    
    private func handleTap() {
        if isOpen {
            snapClosed()
        } else {
            HapticHelper.softTap()
            onTap()
        }
    }
    
    private func triggerLive() {
        HapticHelper.success()
        snapClosed()
        onLiveActivity()
    }
    
    private func triggerShare() {
        HapticHelper.softTap()
        snapClosed()
        onShare()
    }
}

// MARK: - Refined Swipe Action Components

/// Verbesserter Glasmorphismus-Hintergrund für Swipe-Actions
private struct SwipeActionBackground: View {
    let tintColor: Color
    let revealProgress: CGFloat
    let isActive: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDark: Bool { colorScheme == .dark }
    
    var body: some View {
        ZStack {
            // Base: Eleganter Material-Hintergrund
            Rectangle()
                .fill(isDark ? Color.black.opacity(0.4) : Color.white.opacity(0.85))
            
            // Farbiger Glasmorphismus-Layer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            tintColor.opacity((isDark ? 0.25 : 0.15) * revealProgress),
                            tintColor.opacity((isDark ? 0.12 : 0.08) * revealProgress)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Subtiler Top-Schimmer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity((isDark ? 0.12 : 0.35) * revealProgress),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.4)
                    )
                )
            
            // Aktiver Zustand - stärkerer Glow
            if isActive {
                Rectangle()
                    .fill(tintColor.opacity(isDark ? 0.15 : 0.08))
            }
        }
    }
}

/// Verbesserter ButtonStyle für Swipe-Aktionen
private struct RefinedSwipeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
