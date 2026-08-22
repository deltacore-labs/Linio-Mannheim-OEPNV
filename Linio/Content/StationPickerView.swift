//
//  StationPickerView.swift
//  Linio
//

import SwiftUI
import CoreLocation
import MapKit


struct StationPickerView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var graphQLService: GraphQLService
    @ObservedObject var locationManager: LocationManager
    @Binding var selectedStation: Station?
    @Binding var selectedDate: Date

    @Environment(\.dismiss) private var dismiss

    @State private var hasLoadedStations = false
    @State private var searchText = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var recentStations: [Station] = []
    @State private var showNearbyMap = false
    @State private var showAddFavoriteSheet = false
    @State private var stationToFavorite: Station?
    @FocusState private var isSearchFocused: Bool
    
    // Performance: @StateObject für Singleton verhindert unnötige Re-Initialisierungen
    @StateObject private var favoritesManager = FavoriteStationsManager.shared

    // Kürzeres Debounce für schnelleres Feedback
    private let debounceMilliseconds: UInt64 = 300

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.canvas
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Search Bar
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    // MARK: - Content
                    if graphQLService.isLoading && !hasLoadedStations {
                        loadingView
                    } else if searchText.isEmpty {
                        quickActionsView
                    } else if searchText.trimmingCharacters(in: .whitespaces).count < 2 {
                        shortQueryHintView
                    } else if graphQLService.isLoading {
                        VStack(spacing: 0) {
                            inlineLoadingIndicator
                            if !graphQLService.stations.isEmpty {
                                stationList
                            }
                        }
                    } else if graphQLService.stations.isEmpty && hasLoadedStations {
                        emptyStateView
                    } else {
                        stationList
                    }
                }
            }
            .navigationTitle("Haltestelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.primaryColor)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
            loadRecentStations()
        }
        .onChange(of: searchText) { _, newValue in
            handleSearchTextChange(newValue)
        }
        .onDisappear {
            searchDebounceTask?.cancel()
        }
        .sheet(isPresented: $showNearbyMap) {
            if let location = locationManager.location,
               let accessToken = authService.accessToken {
                NearbyStationMapSheet(
                    graphQLService: graphQLService,
                    userLocation: location,
                    accessToken: accessToken
                ) { station in
                    selectAndDismiss(station)
                }
            }
        }
        .sheet(isPresented: $showAddFavoriteSheet) {
            if let station = stationToFavorite {
                AddFavoriteSheet(station: station) {
                    showAddFavoriteSheet = false
                    stationToFavorite = nil
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15, weight: .medium))
                    .accessibilityHidden(true)

                TextField("Haltestelle suchen...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                        guard trimmed.count >= 2 else { return }
                        searchDebounceTask?.cancel()
                        Task { await searchStations(query: trimmed) }
                    }

                if !searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                            graphQLService.stations = []
                            hasLoadedStations = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.6))
                            .font(.system(size: 16))
                    }
                    .transition(.opacity.combined(with: .scale))
                    .accessibilityLabel("Suche löschen")
                }

                if graphQLService.isLoading && !searchText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.7)
                        .transition(.opacity)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSearchFocused ? AppTheme.primary.opacity(0.5) : AppTheme.hairline,
                        lineWidth: isSearchFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
            .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
        }
    }

    // MARK: - Quick Actions (leerer Suchtext)

    private var quickActionsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Datum & Uhrzeit
                dateTimeSection

                // Standort-Buttons
                if locationManager.location != nil {
                    Button {
                        loadNearbyStations()
                        showNearbyMap = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.surfaceStrong)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "map.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.primaryColor)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("In der Nähe")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Haltestellen auf der Karte auswählen")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                        .padding(14)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("In der Nähe: Haltestellen auf der Karte auswählen")
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.surfaceCard)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.hairline, lineWidth: 1))
                    )
                }

                // Favoriten-Haltestellen
                if !favoritesManager.favorites.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.yellow)
                                .accessibilityHidden(true)
                            Text("Favoriten")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(Array(favoritesManager.favorites.enumerated()), id: \.element.id) { index, favorite in
                                Button {
                                    selectAndDismiss(favorite.station)
                                } label: {
                                    favoriteStationRow(favorite: favorite)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(favorite.displayLabel): \(favorite.station.longName)")
                                .accessibilityHint("Tippen zum Auswählen")

                                if index < favoritesManager.favorites.count - 1 {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.surfaceCard)
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.hairline, lineWidth: 1))
                        )
                    }
                }

                // Zuletzt verwendet
                if !recentStations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            Text("Zuletzt verwendet")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            ForEach(Array(recentStations.prefix(5).enumerated()), id: \.element.id) { index, station in
                                Button {
                                    selectAndDismiss(station)
                                } label: {
                                    stationRowContent(station: station)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(station.longName)
                                .accessibilityHint("Tippen zum Auswählen")

                                if index < min(recentStations.count - 1, 4) {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.surfaceCard)
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.hairline, lineWidth: 1))
                        )
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Date & Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Text("Abfahrtzeit")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
            .padding(.horizontal, 4)

            HStack {
                DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(AppTheme.primaryColor)
                Spacer()
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button("Zurücksetzen") { selectedDate = Date() }
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.hairline, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Inline Loading Indicator

    private var inlineLoadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Suche...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryColor))
                .scaleEffect(1.3)
            Text("Suche Haltestellen...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Haltestellen werden gesucht")
    }

    // MARK: - Station List

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Ergebnis-Header
                HStack(spacing: 6) {
                    Text("\(graphQLService.stations.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.ink)
                    Text("Ergebnis\(graphQLService.stations.count == 1 ? "" : "se")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.3)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)

                ForEach(Array(graphQLService.stations.enumerated()), id: \.element.id) { index, station in
                    Button {
                        selectAndDismiss(station)
                    } label: {
                        stationRowContent(station: station)
                    }
                    .buttonStyle(StationRowButtonStyle())
                    .accessibilityLabel(station.longName)
                    .accessibilityHint("Tippen zum Auswählen, lange drücken für Optionen")
                    .contextMenu {
                        if favoritesManager.isFavorite(station: station) {
                            Button(role: .destructive) {
                                favoritesManager.removeFavorite(station: station)
                                HapticHelper.impact(.light)
                            } label: {
                                Label("Aus Favoriten entfernen", systemImage: "star.slash")
                            }
                        } else if favoritesManager.canAddMore {
                            Button {
                                stationToFavorite = station
                                showAddFavoriteSheet = true
                            } label: {
                                Label("Zu Favoriten hinzufügen", systemImage: "star")
                            }
                        }
                    }

                    if index < graphQLService.stations.count - 1 {
                        Divider()
                            .padding(.leading, 70)
                            .padding(.trailing, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.surfaceCard)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.hairline, lineWidth: 1))
                    .padding(.horizontal, 16)
            )
            .padding(.bottom, 30)
        }
    }

    // MARK: - Station Row Content

    @ViewBuilder
    private func stationRowContent(station: Station) -> some View {
        let (city, stopName) = extractCityAndStop(station.longName)

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.07))
                    .frame(width: 38, height: 38)
                Image(systemName: "tram.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.primary)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(city != nil ? stopName : station.longName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let city {
                    Text(city)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.25))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func favoriteStationRow(favorite: FavoriteStation) -> some View {
        let (city, stopName) = extractCityAndStop(favorite.station.longName)

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(favorite.iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: favorite.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(favorite.iconColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(city != nil ? stopName : favorite.station.longName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(favorite.displayLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(favorite.iconColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(favorite.iconColor.opacity(0.12))
                        )
                }

                if let city {
                    Text(city)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.25))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private let rnvCities = [
        "Mannheim", "Heidelberg", "Ludwigshafen", "Weinheim",
        "Schwetzingen", "Viernheim", "Lampertheim", "Speyer",
        "Leimen", "Sandhausen", "Walldorf", "Wiesloch",
        "Hockenheim", "Schriesheim", "Heddesheim", "Eppelheim",
        "Ladenburg", "Ilvesheim", "Dossenheim", "Neckarhausen"
    ]

    private func extractCityAndStop(_ longName: String) -> (city: String?, stopName: String) {
        for city in rnvCities {
            if longName.hasPrefix(city + " ") {
                return (city, String(longName.dropFirst(city.count + 1)))
            }
        }
        return (nil, longName)
    }

    // MARK: - Short Query Hint

    private var shortQueryHintView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(.secondary.opacity(0.3))
            Text("Noch \(2 - searchText.trimmingCharacters(in: .whitespaces).count) Zeichen eingeben")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.06))
                    .frame(width: 80, height: 80)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(.secondary.opacity(0.4))
            }

            Text("Keine Ergebnisse für \"\(searchText.trimmingCharacters(in: .whitespaces))\"")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Versuche einen anderen Suchbegriff\noder prüfe die Schreibweise")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Search Logic

    private func handleSearchTextChange(_ newValue: String) {
        searchDebounceTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespaces)

        guard trimmed.count >= 2 else {
            graphQLService.stations = []
            hasLoadedStations = false
            return
        }

        let delay: UInt64 = trimmed.count >= 3 ? debounceMilliseconds : 400

        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: delay * 1_000_000)
            guard !Task.isCancelled else { return }
            await searchStations(query: trimmed)
        }
    }

    private func searchStations(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let accessToken = authService.accessToken else {
            graphQLService.stations = []
            hasLoadedStations = true
            return
        }

        hasLoadedStations = true

        await graphQLService.searchStationsByName(
            name: query,
            accessToken: accessToken
        )

        graphQLService.stations = rankAndDeduplicate(graphQLService.stations, query: query)

        #if DEBUG
        print("🔍 [StationPicker] Suche '\(query)' → \(graphQLService.stations.count) Ergebnisse")
        for station in graphQLService.stations.prefix(3) {
            print("   • \(station.longName) (hafasID: \(station.hafasID), globalID: \(station.globalID))")
        }
        #endif
    }

    private func rankAndDeduplicate(_ stations: [Station], query: String) -> [Station] {
        let q = query.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        var seen = Set<String>()
        let unique = stations.filter { seen.insert($0.globalID).inserted }
        return unique.sorted { a, b in
            let aN = a.longName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            let bN = b.longName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            let aStarts = aN.hasPrefix(q)
            let bStarts = bN.hasPrefix(q)
            if aStarts != bStarts { return aStarts }
            return aN.localizedCompare(bN) == .orderedAscending
        }
    }

    private func loadNearbyStations() {
        guard let location = locationManager.location else { return }
        guard let accessToken = authService.accessToken else {
            hasLoadedStations = true
            return
        }

        hasLoadedStations = true
        searchText = ""

        Task {
            await graphQLService.searchStations(
                lat: location.latitude,
                lon: location.longitude,
                accessToken: accessToken
            )

            #if DEBUG
            print("📍 [StationPicker] Nahbereich → \(graphQLService.stations.count) Ergebnisse")
            for station in graphQLService.stations.prefix(3) {
                print("   • \(station.longName) (globalID: \(station.globalID))")
            }
            #endif
        }
    }

    // MARK: - Selection & Recent Stations

    private func selectAndDismiss(_ station: Station) {
        #if DEBUG
        print("✅ [StationPicker] Ausgewählt: \(station.longName) (globalID: \(station.globalID))")
        #endif
        HapticHelper.selection()
        selectedStation = station
        saveRecentStation(station)
        dismiss()
    }

    private let recentStationsKey = "recentStations"
    private let maxRecentStations = 8

    private func saveRecentStation(_ station: Station) {
        var recents = loadRecentStationsFromDefaults()
        recents.removeAll { $0.globalID == station.globalID }
        recents.insert(station, at: 0)
        if recents.count > maxRecentStations {
            recents = Array(recents.prefix(maxRecentStations))
        }
        if let data = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(data, forKey: recentStationsKey)

            // Stationen zusätzlich in App Group spiegeln (für Widget-Intent-Vorschläge)
            if let groupDefaults = UserDefaults(suiteName: AppConfiguration.appGroupID),
               let data = try? JSONEncoder().encode(recents) {
                groupDefaults.set(data, forKey: "widgetRecentStations")
            }
        }
    }

    private func loadRecentStations() {
        recentStations = loadRecentStationsFromDefaults()
    }

    private func loadRecentStationsFromDefaults() -> [Station] {
        guard let data = UserDefaults.standard.data(forKey: recentStationsKey),
              let stations = try? JSONDecoder().decode([Station].self, from: data) else {
            return []
        }
        return stations
    }
}

// MARK: - Nearby Station Map Sheet

struct NearbyStationMapSheet: View {
    @ObservedObject var graphQLService: GraphQLService
    let userLocation: CLLocationCoordinate2D
    let accessToken: String
    let onSelect: (Station) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Station?
    @State private var mapCenter: CLLocationCoordinate2D
    @State private var allStations: [Station] = []
    @State private var isLoadingMore = false

    init(graphQLService: GraphQLService, userLocation: CLLocationCoordinate2D, accessToken: String, onSelect: @escaping (Station) -> Void) {
        self.graphQLService = graphQLService
        self.userLocation = userLocation
        self.accessToken = accessToken
        self.onSelect = onSelect
        self._mapCenter = State(initialValue: userLocation)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(initialPosition: .region(
                MKCoordinateRegion(center: userLocation, latitudinalMeters: 900, longitudinalMeters: 900)
            )) {

                UserAnnotation()
                ForEach(allStations) { station in
                    if let lat = station.latitude, let lon = station.longitude {
                        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let isSelected = selected?.globalID == station.globalID
                        Annotation("", coordinate: coord, anchor: .bottom) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                    selected = isSelected ? nil : station
                                }
                            } label: {
                                stationPin(isSelected: isSelected, name: station.longName)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(station.longName)
                            .accessibilityHint(isSelected ? "Tippen zum Abwählen" : "Tippen zum Auswählen")
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including([.publicTransport])))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCenter = context.camera.centerCoordinate
            }
            .ignoresSafeArea()
            .safeAreaPadding(.bottom, selected != nil ? 140 : 0)

            if graphQLService.isLoading {
                VStack(spacing: 8) {
                    ProgressView().tint(.white)
                    Text("Haltestellen laden…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Haltestellen werden geladen")
                .padding(.bottom, 160)
            }

            loadMoreButton
                .padding(.bottom, selected != nil ? 156 : 16)

            if let station = selected {
                selectionCard(station: station)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 16)
            .padding(.leading, 16)
            .accessibilityLabel("Abbrechen")
        }
        .onAppear {
            let fresh = graphQLService.stations.filter { s in
                !allStations.contains(where: { $0.globalID == s.globalID })
            }
            allStations.append(contentsOf: fresh)
        }
        .onChange(of: graphQLService.stations) { _, newStations in
            let fresh = newStations.filter { s in
                !allStations.contains(where: { $0.globalID == s.globalID })
            }
            allStations.append(contentsOf: fresh)
        }
    }

    private func loadMoreStations() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        await graphQLService.searchStations(lat: mapCenter.latitude, lon: mapCenter.longitude, accessToken: accessToken)
        isLoadingMore = false
    }

    @ViewBuilder
    private func stationPin(isSelected: Bool, name: String) -> some View {
        VStack(spacing: 3) {
            if isSelected {
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.onPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.primaryColor))
                    .shadow(color: AppTheme.primaryColor.opacity(0.35), radius: 4, x: 0, y: 2)
            }
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.primaryColor : Color(.systemBackground))
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
                Image(systemName: "tram.fill")
                    .font(.system(size: isSelected ? 15 : 11, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.onPrimary : AppTheme.primaryColor)
            }
            if !isSelected {
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: isSelected)
    }

    private func selectionCard(station: Station) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.primaryColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "tram.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.longName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Text("Haltestelle auswählen")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    onSelect(station)
                } label: {
                    Text("Auswählen")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.onPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(AppTheme.primaryColor))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: -4)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private var loadMoreButton: some View {
        Button {
            Task { await loadMoreStations() }
        } label: {
            HStack(spacing: 8) {
                if isLoadingMore {
                    ProgressView()
                        .tint(AppTheme.primaryColor)
                        .scaleEffect(0.85)
                    Text("Wird geladen…")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryColor)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryColor)
                    Text("Weitere laden")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
        }
        .disabled(graphQLService.isLoading || isLoadingMore)
    }
}

// MARK: - Station Row Button Style

struct StationRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.secondary.opacity(0.08)
                    : Color.clear
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    StationPickerView(
        authService: AuthService(),
        graphQLService: GraphQLService(),
        locationManager: LocationManager(),
        selectedStation: .constant(nil),
        selectedDate: .constant(Date())
    )
}
