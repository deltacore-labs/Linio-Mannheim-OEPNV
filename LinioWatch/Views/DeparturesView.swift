import SwiftUI
import CoreLocation

struct DeparturesView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @StateObject private var cache = WatchCacheManager.shared
    @StateObject private var locationManager = WatchLocationManager.shared
    @State private var selectedStationID   = WatchStation.all.first?.id   ?? "de:08222:115"
    @State private var selectedStationName = WatchStation.all.first?.name ?? "MA Hauptbahnhof"
    @State private var showingFavorites = false
    @State private var lastRefreshTime: Date?
    @State private var isLoadingNearby = false

    var body: some View {
        NavigationStack {
            List {
                // "In der Nähe" Button
                Section {
                    NearbyStationButton(
                        isLoading: $isLoadingNearby,
                        onStationSelected: { station in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedStationID = station.id
                                selectedStationName = station.name
                            }
                        }
                    )
                    .environmentObject(connectivity)
                }
                
                // Favoriten Quick Access (wenn vorhanden)
                if !cache.favoriteStations.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(cache.favoriteStations) { station in
                                    FavoriteChip(
                                        station: station,
                                        isSelected: station.id == selectedStationID
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedStationID = station.id
                                            selectedStationName = station.name
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        .listRowBackground(Color.clear)
                    }
                }
                
                // Station Picker
                Section {
                    NavigationLink(destination: ImprovedStationPickerView(
                        title: "Haltestelle".localized,
                        stationID: $selectedStationID,
                        stationName: $selectedStationName
                    )) {
                        HStack {
                            Image(systemName: "tram.fill")
                                .foregroundColor(.blue)
                            Text(selectedStationName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            if cache.isFavorite(selectedStationID) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            let station = WatchStation(id: selectedStationID, name: selectedStationName)
                            cache.toggleFavorite(station)
                        } label: {
                            Label(cache.isFavorite(selectedStationID) ? "Entfernen" : "Favorit",
                                  systemImage: cache.isFavorite(selectedStationID) ? "star.slash" : "star.fill")
                        }
                        .tint(cache.isFavorite(selectedStationID) ? .red : .yellow)
                    }
                }

                // Departure List
                DepartureListSection(
                    connectivity: connectivity,
                    cache: cache,
                    stationID: selectedStationID,
                    onRetry: { loadDepartures(forceRefresh: true) }
                )
            }
            .navigationTitle("Abfahrten".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { loadDepartures(forceRefresh: true) } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .disabled(connectivity.isLoading)
                }
            }
            .onAppear { loadDepartures() }
            .onChange(of: selectedStationID) { _, newID in
                cache.saveLastSelectedStation(id: newID, name: selectedStationName)
                loadDepartures()
            }
            .onChange(of: connectivity.isReachable) { _, isReachable in
                guard isReachable, connectivity.departures.isEmpty, !connectivity.isLoading else { return }
                loadDepartures()
            }
            .onChange(of: connectivity.departures) { _, deps in
                if !deps.isEmpty {
                    cache.cacheDepartures(deps, forStation: selectedStationID)
                    lastRefreshTime = Date()
                }
            }
        }
    }

    private func loadDepartures(forceRefresh: Bool = false) {
        // Cache Check
        if !forceRefresh, let cached = cache.getCachedDepartures(forStation: selectedStationID) {
            connectivity.departures = cached
            return
        }
        
        // Offline Check mit Cache
        if !connectivity.isReachable, let offline = cache.getOfflineDepartures(forStation: selectedStationID) {
            connectivity.departures = offline
            connectivity.lastError = "Offline-Daten".localized
            return
        }
        
        connectivity.requestDepartures(stationID: selectedStationID, stationName: selectedStationName)
    }
}

// MARK: - Abfahrts-Zeile

private struct DepartureRow: View {
    let departure: WatchDeparture

    private var displayTime: String {
        departure.estimatedTime ?? departure.scheduledTime
    }

    var body: some View {
        HStack(spacing: 6) {
            LineBadgeView(
                serviceName: departure.lineName,
                serviceType: departure.serviceType
            )

            VStack(alignment: .leading, spacing: 2) {
                if !departure.direction.isEmpty {
                    Text(departure.direction)
                        .font(.caption.bold())
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Text(WatchDateHelper.formatTime(displayTime))
                        .font(.system(.caption2, design: .monospaced).bold())

                    if let delay = departure.delayMinutes, delay > 0 {
                        Text("+\(delay)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                    } else if let mins = WatchDateHelper.minutesUntil(displayTime) {
                        Text(mins == 0 ? "jetzt" : "in \(mins)'")
                            .font(.caption2)
                            .foregroundColor(mins <= 2 ? .orange : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 1)
    }
}

// MARK: - Leer- und Fehlerzustände

private struct EmptyDeparturesRow: View {
    let isReachable: Bool
    let onLoad: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: isReachable ? "tray" : "iphone.slash")
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text(isReachable ? "Keine Abfahrten".localized : "iPhone nicht erreichbar".localized)
                .font(.caption.bold())
                .multilineTextAlignment(.center)

            if isReachable {
                Button("Laden".localized, action: onLoad)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Favorite Chip

private struct FavoriteChip: View {
    let station: WatchStation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(station.name.replacingOccurrences(of: "Mannheim ", with: "MA ")
                           .replacingOccurrences(of: "Heidelberg ", with: "HD ")
                           .replacingOccurrences(of: "Ludwigshafen ", with: "LU "))
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Departure List Section

private struct DepartureListSection: View {
    @ObservedObject var connectivity: WatchConnectivityManager
    @ObservedObject var cache: WatchCacheManager
    let stationID: String
    let onRetry: () -> Void
    
    var body: some View {
        if connectivity.isLoading {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Lade Abfahrten…".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        } else if let error = connectivity.lastError {
            ErrorRow(message: error, retry: onRetry)
        } else if connectivity.departures.isEmpty {
            EmptyDeparturesRow(isReachable: connectivity.isReachable, onLoad: onRetry)
        } else {
            ForEach(connectivity.departures) { dep in
                DepartureRow(departure: dep)
            }
        }
    }
}

// MARK: - Improved Station Picker

struct ImprovedStationPickerView: View {
    let title: String
    @Binding var stationID: String
    @Binding var stationName: String
    @StateObject private var cache = WatchCacheManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // Favoriten Section
            if !cache.favoriteStations.isEmpty {
                Section("Favoriten".localized) {
                    ForEach(cache.favoriteStations) { station in
                        StationRow(station: station, isSelected: station.id == stationID) {
                            selectStation(station)
                        }
                    }
                }
            }
            
            // Alle Stationen
            Section("Alle Haltestellen".localized) {
                ForEach(WatchStation.all) { station in
                    StationRow(station: station, isSelected: station.id == stationID) {
                        selectStation(station)
                    }
                }
            }
        }
        .navigationTitle(title)
    }
    
    private func selectStation(_ station: WatchStation) {
        stationID = station.id
        stationName = station.name
        dismiss()
    }
}

private struct StationRow: View {
    let station: WatchStation
    let isSelected: Bool
    let onSelect: () -> Void
    @StateObject private var cache = WatchCacheManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.caption)
                        .foregroundColor(isSelected ? .blue : .primary)
                }
                Spacer()
                if cache.isFavorite(station.id) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button {
                cache.toggleFavorite(station)
            } label: {
                Label(cache.isFavorite(station.id) ? "Entfernen" : "Favorit",
                      systemImage: cache.isFavorite(station.id) ? "star.slash" : "star.fill")
            }
            .tint(cache.isFavorite(station.id) ? .red : .yellow)
        }
    }
}

// MARK: - Nearby Station Button

private struct NearbyStationButton: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @StateObject private var locationManager = WatchLocationManager.shared
    @Binding var isLoading: Bool
    let onStationSelected: (WatchStation) -> Void
    
    var body: some View {
        Button {
            Task { await findNearbyStation() }
        } label: {
            HStack(spacing: 8) {
                if isLoading || connectivity.nearbyLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Text("In der Nähe".localized)
                    .font(.caption)
                Spacer()
                if let error = connectivity.nearbyError ?? locationManager.errorMessage {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .disabled(isLoading || connectivity.nearbyLoading)
        .onChange(of: connectivity.nearbyStations) { _, stations in
            if let first = stations.first {
                onStationSelected(first)
                isLoading = false
            }
        }
    }
    
    private func findNearbyStation() async {
        isLoading = true
        
        // Standort anfordern
        guard let location = await locationManager.requestLocation() else {
            isLoading = false
            return
        }
        
        // Stationen in der Nähe beim iPhone anfragen
        connectivity.requestNearbyStations(latitude: location.latitude, longitude: location.longitude)
    }
}

private struct ErrorRow: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Erneut".localized, action: retry)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
}

#if DEBUG
#Preview("Abfahrten") {
    let conn = WatchConnectivityManager.shared
    conn.departures = WatchDemoData.departures
    return DeparturesView()
        .environmentObject(conn)
}

#Preview("Laden") {
    let conn = WatchConnectivityManager.shared
    conn.isLoading = true
    return DeparturesView()
        .environmentObject(conn)
}

#Preview("Fehler") {
    let conn = WatchConnectivityManager.shared
    conn.lastError = "iPhone nicht erreichbar"
    return DeparturesView()
        .environmentObject(conn)
}
#endif
