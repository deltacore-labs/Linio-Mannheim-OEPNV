import SwiftUI
import CoreLocation

struct ConnectionSearchView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @StateObject private var locationManager = WatchLocationManager.shared
    @State private var fromID   = WatchStation.all.first?.id                    ?? "de:08222:115"
    @State private var fromName = WatchStation.all.first?.name                  ?? "MA Hauptbahnhof"
    @State private var toID     = WatchStation.all.dropFirst().first?.id         ?? "de:08222:101"
    @State private var toName   = WatchStation.all.dropFirst().first?.name       ?? "MA Paradeplatz"
    @State private var isLoadingNearby = false

    var body: some View {
        NavigationStack {
            List {
                // "In der Nähe als Start" Button
                Section {
                    Button {
                        Task { await setNearbyAsStart() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoadingNearby || connectivity.nearbyLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            Text("Standort als Start".localized)
                                .font(.caption)
                        }
                    }
                    .disabled(isLoadingNearby || connectivity.nearbyLoading)
                }
                
                Section {
                    NavigationLink(destination: ImprovedStationPickerView(
                        title: "Von".localized,
                        stationID: $fromID,
                        stationName: $fromName
                    )) {
                        LabeledStationRow(label: "Von".localized, name: fromName)
                    }

                    NavigationLink(destination: ImprovedStationPickerView(
                        title: "Nach".localized,
                        stationID: $toID,
                        stationName: $toName
                    )) {
                        LabeledStationRow(label: "Nach".localized, name: toName)
                    }
                }

                Section {
                    Button(action: search) {
                        HStack {
                            Spacer()
                            Label("Suchen".localized, systemImage: "magnifyingglass")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(fromID == toID || connectivity.connectionsLoading)
                }

                if connectivity.connectionsLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .listRowBackground(Color.clear)
                } else if let error = connectivity.connectionsError {
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(error).font(.caption2).foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button("Erneut".localized, action: search).font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(connectivity.connectionResults) { trip in
                        NavigationLink(destination: WatchTripDetailView(trip: trip)) {
                            ConnectionResultRow(trip: trip)
                        }
                    }
                }
            }
            .navigationTitle("Verbindungen".localized)
            .onChange(of: connectivity.nearbyStations) { _, stations in
                if let first = stations.first, isLoadingNearby {
                    fromID = first.id
                    fromName = first.name
                    isLoadingNearby = false
                }
            }
        }
    }

    private func search() {
        connectivity.requestConnections(
            fromID: fromID, toID: toID,
            fromName: fromName, toName: toName
        )
    }
    
    private func setNearbyAsStart() async {
        isLoadingNearby = true
        
        guard let location = await locationManager.requestLocation() else {
            isLoadingNearby = false
            return
        }
        
        connectivity.requestNearbyStations(latitude: location.latitude, longitude: location.longitude)
    }
}

// MARK: - Haltestellen-Zeile

private struct LabeledStationRow: View {
    let label: String
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(name)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

// MARK: - Ergebnis-Zeile

private struct ConnectionResultRow: View {
    let trip: TripData

    private var firstLeg: TripLegData? { trip.legs.first(where: { $0.isTimedLeg }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let leg = firstLeg {
                    LineBadgeView(serviceName: leg.serviceName, serviceType: leg.serviceType)
                }
                Spacer()
                if trip.interchanges > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 8))
                        Text("\(trip.interchanges)×").font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 3) {
                Text(WatchDateHelper.formatTime(trip.startTime))
                    .font(.system(.callout, design: .monospaced).bold())
                Image(systemName: "arrow.right").font(.caption2).foregroundColor(.secondary)
                Text(WatchDateHelper.formatTime(trip.endTime))
                    .font(.system(.callout, design: .monospaced)).foregroundColor(.secondary)
                Spacer()
                Text(WatchDateHelper.durationString(start: trip.startTime, end: trip.endTime))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Trip-Detail (Legs)

struct WatchTripDetailView: View {
    let trip: TripData

    private var timedLegs: [TripLegData] { trip.legs.filter { $0.isTimedLeg } }

    var body: some View {
        List {
            ForEach(Array(timedLegs.enumerated()), id: \.offset) { _, leg in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        LineBadgeView(serviceName: leg.serviceName, serviceType: leg.serviceType)
                        if let dest = leg.destinationLabel {
                            Text("→ \(dest)").font(.caption2).foregroundColor(.secondary).lineLimit(1)
                        }
                    }
                    HStack(spacing: 6) {
                        Text(WatchDateHelper.formatTime(leg.departureTime ?? ""))
                            .font(.system(.footnote, design: .monospaced).bold())
                        Text(leg.boardStopName ?? "").font(.footnote).lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Text(WatchDateHelper.formatTime(leg.arrivalTime ?? ""))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(leg.alightStopName ?? "").font(.footnote).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("\(trip.startStation) → \(trip.endStation)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
