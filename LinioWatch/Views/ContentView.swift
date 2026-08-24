import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @StateObject private var hapticManager = WatchHapticManager.shared
    @StateObject private var localization = WatchLocalizationManager.shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ActiveTripView()
                .tag(0)
                .tabItem { Label("Fahrt".localized, systemImage: "tram.fill") }

            SavedTripsView()
                .tag(1)
                .tabItem { Label("Geplant".localized, systemImage: "calendar") }

            DeparturesView()
                .tag(2)
                .tabItem { Label("Abfahrten".localized, systemImage: "clock") }

            ConnectionSearchView()
                .tag(3)
                .tabItem { Label("Suche".localized, systemImage: "magnifyingglass") }

            WorkoutView()
                .tag(4)
                .tabItem { Label("Fußweg".localized, systemImage: "figure.walk") }

            DebugView()
                .tag(5)
                .tabItem { Label("Debug", systemImage: "ladybug") }
        }
        .onOpenURL { _ in
            // Komplikation angetippt → zur aktiven Fahrt navigieren
            selectedTab = 0
        }
        .onChange(of: dataManager.activeTrip) { oldTrip, newTrip in
            // Haptic Monitoring für aktive Fahrt starten/stoppen
            if let trip = newTrip {
                hapticManager.startMonitoring(for: trip)
            } else {
                hapticManager.stopMonitoring()
            }
        }
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

