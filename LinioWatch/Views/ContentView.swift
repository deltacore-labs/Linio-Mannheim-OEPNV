import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @StateObject private var hapticManager = WatchHapticManager.shared
    @StateObject private var localization = WatchLocalizationManager.shared
    @State private var selectedTab = 0
    @State private var showQuickActions = false
    
    private var hasActiveTrip: Bool { dataManager.activeTrip != nil }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Aktive Fahrt (mit Badge wenn vorhanden)
            ActiveTripView()
                .tag(0)
                .tabItem { 
                    Label("Fahrt".localized, systemImage: hasActiveTrip ? "tram.fill" : "tram")
                }

            // Geplante Fahrten
            SavedTripsView()
                .tag(1)
                .tabItem { 
                    Label("Geplant".localized, systemImage: "calendar") 
                }

            // Abfahrten
            DeparturesView()
                .tag(2)
                .tabItem { 
                    Label("Abfahrten".localized, systemImage: "clock.fill") 
                }

            // Verbindungssuche
            ConnectionSearchView()
                .tag(3)
                .tabItem { 
                    Label("Suche".localized, systemImage: "magnifyingglass") 
                }

            // Einstellungen & Debug
            SettingsView()
                .tag(4)
                .tabItem { 
                    Label("Mehr".localized, systemImage: "ellipsis.circle") 
                }
        }
        .tabViewStyle(.verticalPage)
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: dataManager.activeTrip) { oldTrip, newTrip in
            if let trip = newTrip {
                hapticManager.startMonitoring(for: trip)
                // Automatisch zur aktiven Fahrt wechseln wenn neue gestartet wird
                if oldTrip == nil {
                    withAnimation { selectedTab = 0 }
                }
            } else {
                hapticManager.stopMonitoring()
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        switch url.host {
        case "activeTrip", "trip":
            selectedTab = 0
        case "departures":
            selectedTab = 2
        case "search":
            selectedTab = 3
        default:
            selectedTab = 0
        }
    }
}

// MARK: - Settings View (Ersetzt Debug View für Endnutzer)

struct SettingsView: View {
    @StateObject private var cache = WatchCacheManager.shared
    @State private var showDebug = false
    
    var body: some View {
        List {
            Section("Statistiken".localized) {
                HStack {
                    Text("Cache-Treffer".localized)
                    Spacer()
                    Text("\(Int(cache.cacheStats.hitRate * 100))%")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Gespart".localized)
                    Spacer()
                    Text("\(cache.cacheStats.savedAPICallsCount) Anfragen")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Favoriten".localized) {
                if cache.favoriteStations.isEmpty {
                    Text("Keine Favoriten".localized)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(cache.favoriteStations) { station in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(station.name)
                                .font(.caption)
                        }
                    }
                    .onDelete { indices in
                        indices.forEach { cache.favoriteStations.remove(at: $0) }
                    }
                }
            }
            
            Section("Cache".localized) {
                Button(role: .destructive) {
                    cache.clearAllCaches()
                } label: {
                    Label("Cache leeren".localized, systemImage: "trash")
                }
            }
            
            Section {
                NavigationLink("Debug-Infos".localized) {
                    DebugView()
                }
            }
        }
        .navigationTitle("Einstellungen".localized)
    }
}

#if DEBUG
#Preview("Aktive Fahrt") {
    let dm = WatchDataManager()
    dm.activeTrip = WatchDemoData.activeTrip
    return ContentView()
        .environmentObject(dm)
        .environmentObject(WatchConnectivityManager.shared)
}

#Preview("Geplante Fahrten") {
    let dm = WatchDataManager()
    dm.savedTrips = WatchDemoData.savedTrips
    return ContentView()
        .environmentObject(dm)
        .environmentObject(WatchConnectivityManager.shared)
}
#endif

