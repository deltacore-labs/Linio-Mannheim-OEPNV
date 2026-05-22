//  SteigSheet.swift
//  RNV-Transport-App

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
    @Environment(\.colorScheme) private var colorScheme
    private let formatter = DateFormattingHelper.shared

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

    private var selectedLetter: String? {
        departure.quayText.flatMap {
            $0.split(separator: " ").last.map(String.init)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if !quays.isEmpty {
                    mapView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                departureList
            }
        }
        .background(AppTheme.canvasAdaptive(colorScheme))
        .task {
            guard let token = authService.accessToken else {
                isLoadingQuays = false
                return
            }
            quays = await graphQLService.getStationQuays(
                hafasID: station.hafasID,
                accessToken: token
            )
            isLoadingQuays = false
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(station.longName)
                .font(.caption)
                .foregroundColor(AppTheme.muted)
            Text(departure.quayText ?? "Unbekannter Steig")
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.inkAdaptive(colorScheme))
            if !linesAtQuay.isEmpty {
                Text("Linie " + linesAtQuay.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(AppTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: MapKit-Karte

    private var mapView: some View {
        Map(
            coordinateRegion: .constant(mapRegion),
            showsUserLocation: true,
            annotationItems: quays
        ) { quay in
            MapAnnotation(coordinate: quay.coordinate) {
                PlatformPin(
                    letter: quay.letter,
                    isHighlighted: quay.letter == selectedLetter
                )
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }

    private var mapRegion: MKCoordinateRegion {
        guard !quays.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.48, longitude: 8.47),
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
        let lats = quays.map { $0.coordinate.latitude }
        let lons = quays.map { $0.coordinate.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.8, 0.002),
            longitudeDelta: max((maxLon - minLon) * 1.8, 0.002)
        )
        return MKCoordinateRegion(center: center, span: span)
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
                        .foregroundColor(AppTheme.inkAdaptive(colorScheme))
                        .lineLimit(1)
                    Spacer()
                    if let mins = dep.minutesUntilDeparture {
                        Text(mins == 0 ? "jetzt" : "\(mins) min")
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundColor(mins <= 1 ? AppTheme.semanticSuccess : AppTheme.inkAdaptive(colorScheme))
                    } else {
                        Text(formatter.formatTime(dep.scheduledDeparture))
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundColor(AppTheme.inkAdaptive(colorScheme))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if index < departuresAtQuay.count - 1 {
                    AppTheme.hairlineAdaptive(colorScheme)
                        .frame(height: 1)
                        .padding(.leading, 20)
                }
            }
        }
    }
}

// MARK: - PlatformPin

private struct PlatformPin: View {
    let letter: String
    let isHighlighted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isHighlighted ? Color.orange : Color(red: 0.23, green: 0.23, blue: 0.42))
                .frame(width: isHighlighted ? 30 : 22, height: isHighlighted ? 30 : 22)
                .shadow(color: isHighlighted ? .orange.opacity(0.5) : .clear, radius: 6)
            Circle()
                .stroke(
                    isHighlighted ? Color.orange.opacity(0.4) : Color.blue.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: isHighlighted ? 30 : 22, height: isHighlighted ? 30 : 22)
            Text(letter)
                .font(.system(size: isHighlighted ? 13 : 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
