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
            // Farbiger Akzent-Streifen links
            RoundedRectangle(cornerRadius: 2)
                .fill(isPast ? SemanticColor.separator : primaryLineColor)
                .frame(width: 4)
                .padding(.vertical, 8)

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
            .padding(.vertical, DesignTokens.Spacing.sm + 2)
        }
        .background(
            ZStack {
                // Base Card Background
                LiquidGlassBackground(
                    cornerRadius: DesignTokens.CornerRadius.large,
                    intensity: isPast ? .subtle : .standard
                )
                
                // Subtle Gradient Overlay für Tiefe
                if !isPast {
                    LinearGradient(
                        colors: [primaryLineColor.opacity(0.03), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                }
            }
            .opacity(isPast ? 0.6 : 1.0)
        )
        .overlay(
            // Subtiler Border für bessere Definition
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .stroke(
                    isPast ? SemanticColor.separator.opacity(0.3) : primaryLineColor.opacity(0.15),
                    lineWidth: 0.5
                )
        )
        .opacity(isPast ? 0.72 : 1.0)
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

// MARK: - Swipeable Trip Card

/// Eine TripCard mit Swipe-Gesten für Live Activity und Teilen
struct SwipeableTripCard: View {
    let trip: DetailedTrip
    let onTap: () -> Void
    let onLiveActivity: () -> Void
    let onShare: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let actionThreshold: CGFloat = 70
    private let maxOffset: CGFloat = 90
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Hintergrund-Aktionen
            HStack(spacing: 0) {
                // Linke Aktion (Teilen)
                actionButton(icon: "square.and.arrow.up", text: "Teilen", 
                           color: AppTheme.primaryColor, isActive: offset > actionThreshold)
                    .frame(width: max(offset, 0))
                    .clipped()
                
                Spacer()
                
                // Rechte Aktion (Live Activity)
                actionButton(icon: "bolt.fill", text: "Live",
                           color: .green, isActive: offset < -actionThreshold)
                    .frame(width: max(-offset, 0))
                    .clipped()
            }
            
            // Die eigentliche TripCard
            Button(action: {
                if !isSwiping { onTap() }
            }) {
                TripCard(trip: trip)
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        isSwiping = true
                        let translation = value.translation.width
                        // Nur horizontale Swipes verarbeiten
                        guard abs(translation) > abs(value.translation.height) else { return }
                        // Elastischer Widerstand
                        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.86)) {
                            if translation > 0 {
                                offset = min(translation * 0.7, maxOffset)
                            } else {
                                offset = max(translation * 0.7, -maxOffset)
                            }
                        }
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                            if offset > actionThreshold || (offset > 25 && velocity > 80) {
                                offset = 0
                                onShare()
                            } else if offset < -actionThreshold || (offset < -25 && velocity < -80) {
                                offset = 0
                                onLiveActivity()
                            } else {
                                offset = 0
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { isSwiping = false }
                    }
            )
        }
    }
    
    @ViewBuilder
    private func actionButton(icon: String, text: String, color: Color, isActive: Bool) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isActive ? 0.25 : 0.15))
                    .frame(width: isActive ? 44 : 36)
                Image(systemName: icon)
                    .font(.system(size: isActive ? 20 : 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [color.opacity(isActive ? 1 : 0.85), color.opacity(isActive ? 0.9 : 0.75)],
                          startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .animation(.spring(response: 0.2), value: isActive)
    }
}
