//  SteigSheet.swift
//  Linio

import SwiftUI
import MapKit

// MARK: - SteigSheet

struct SteigSheet: View {
    let departure: Departure
    let allDepartures: [Departure]
    let station: Station
    let graphQLService: GraphQLService
    let authService: AuthService

    @State private var quays: [StationQuay] = []
    @State private var isLoadingQuays = true
    @State private var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.48, longitude: 8.47),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    ))
    @Environment(\.dismiss) private var dismiss
    private let formatter = DateFormattingHelper.shared

    private let mapPreviewHeight: CGFloat = 250

    private var departuresAtQuay: [Departure] {
        allDepartures
            .filter { $0.quayText == departure.quayText }
            .sorted {
                let fmt = DateFormattingHelper.shared
                let a = fmt.parseISO8601($0.scheduledDeparture) ?? .distantFuture
                let b = fmt.parseISO8601($1.scheduledDeparture) ?? .distantFuture
                return a < b
            }
    }

    private var linesAtQuay: [String] {
        Array(Set(departuresAtQuay.map { $0.lineName })).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if !quays.isEmpty {
                mapView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            ScrollView {
                departureList
            }
        }
        .background(AppTheme.canvas)
        .task {
            guard let token = authService.accessToken else {
                isLoadingQuays = false
                return
            }
            quays = await graphQLService.getStationQuays(
                hafasID: station.hafasID,
                accessToken: token
            )
            mapPosition = .region(StationQuay.boundingRegion(for: quays))
            isLoadingQuays = false
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(station.longName)
                    .font(.caption)
                    .foregroundColor(AppTheme.muted)
                Text(departure.quayText ?? "Unbekannter Steig")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.ink)
                if !linesAtQuay.isEmpty {
                    Text("Linie " + linesAtQuay.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(AppTheme.muted)
                }
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.muted)
            }
            .accessibilityLabel("Schließen")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: MapKit-Karte

    private var mapView: some View {
        Map(position: $mapPosition) {
            ForEach(quays) { quay in
                Annotation(quay.letter, coordinate: quay.coordinate, anchor: .center) {
                    PlatformPin(
                        letter: quay.letter,
                        isHighlighted: quay.letter == departure.quayLetter
                    )
                }
            }
        }
        .mapStyle(.standard)
        .frame(height: mapPreviewHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Abfahrtsliste

    private var departureList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NÄCHSTE ABFAHRTEN")
                .font(.caption2.weight(.semibold))
                .foregroundColor(AppTheme.muted)
                .tracking(0.8)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            ForEach(Array(departuresAtQuay.enumerated()), id: \.element.id) { index, dep in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(dep.lineColor)
                            .frame(width: 32, height: 32)
                        Text(dep.lineName)
                            .font(.caption.weight(.black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Text(dep.direction)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.ink)
                        .lineLimit(1)
                    Spacer()
                    if let mins = dep.minutesUntilDeparture {
                        Text(mins == 0 ? "jetzt" : "\(mins) min")
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundColor(mins <= 1 ? AppTheme.semanticSuccess : AppTheme.ink)
                    } else {
                        Text(formatter.formatTime(dep.scheduledDeparture))
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundColor(AppTheme.ink)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel({
                    let timeText: String
                    if let mins = dep.minutesUntilDeparture {
                        timeText = mins == 0 ? "jetzt" : "in \(mins) Minuten"
                    } else {
                        timeText = formatter.formatTime(dep.scheduledDeparture)
                    }
                    return "\(dep.lineName) Richtung \(dep.direction), \(timeText)"
                }())

                if index < departuresAtQuay.count - 1 {
                    AppTheme.hairline
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

// MARK: - PlatformPin

struct PlatformPin: View {
    let letter: String
    let isHighlighted: Bool

    private var pinSize: CGFloat {
        let n = letter.count
        if isHighlighted { return n >= 3 ? 38 : n == 2 ? 34 : 30 }
        return n >= 3 ? 30 : n == 2 ? 26 : 22
    }

    private var fontSize: CGFloat {
        let n = letter.count
        if isHighlighted { return n >= 3 ? 10 : n == 2 ? 11 : 13 }
        return n >= 3 ? 7.5 : n == 2 ? 9 : 10
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isHighlighted ? Color.orange : Color(red: 0.23, green: 0.23, blue: 0.42))
                .frame(width: pinSize, height: pinSize)
                .shadow(color: isHighlighted ? .orange.opacity(0.5) : .clear, radius: 6)
            Circle()
                .stroke(
                    isHighlighted ? Color.orange.opacity(0.4) : Color.blue.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: pinSize, height: pinSize)
            Text(letter)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    let now = ISO8601DateFormatter().string(from: Date())
    let in5  = ISO8601DateFormatter().string(from: Date().addingTimeInterval(5 * 60))
    let in12 = ISO8601DateFormatter().string(from: Date().addingTimeInterval(12 * 60))

    let dep1 = Departure(
        scheduledDeparture: now,
        estimatedDeparture: in5,
        lineName: "3",
        direction: "Sandhofen",
        serviceType: "TRAM",
        quayText: "Steig A"
    )
    let dep2 = Departure(
        scheduledDeparture: in5,
        estimatedDeparture: nil,
        lineName: "3",
        direction: "Sandhofen",
        serviceType: "TRAM",
        quayText: "Steig A"
    )
    let dep3 = Departure(
        scheduledDeparture: in12,
        estimatedDeparture: nil,
        lineName: "4",
        direction: "Neckarau",
        serviceType: "TRAM",
        quayText: "Steig B"
    )

    let station = Station(
        hafasID: "2264",
        globalID: "de:08222:2264",
        longName: "Mannheim Hauptbahnhof",
        latitude: nil,
        longitude: nil
    )

    SteigSheet(
        departure: dep1,
        allDepartures: [dep1, dep2, dep3],
        station: station,
        graphQLService: GraphQLService(),
        authService: AuthService()
    )
}
