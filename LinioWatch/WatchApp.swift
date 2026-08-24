// LinioWatch – Apple Watch App für Linio

import SwiftUI
import WidgetKit

@main
struct LinioWatchApp: App {
    @StateObject private var dataManager = WatchDataManager()
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @StateObject private var hapticManager = WatchHapticManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environmentObject(connectivity)
                .onAppear {
                    dataManager.refresh()
                    connectivity.onContextUpdated = { [weak dataManager] in
                        dataManager?.refresh()
                        // Complication aktualisieren wenn sich Daten ändern
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    connectivity.requestInitialData()
                }
                .onDisappear {
                    connectivity.onContextUpdated = nil
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                dataManager.refresh()
                dataManager.startAutoRefresh()
                // Haptic Monitoring fortsetzen wenn aktive Fahrt vorhanden
                if let trip = dataManager.activeTrip {
                    hapticManager.startMonitoring(for: trip)
                }
            } else if newPhase == .background || newPhase == .inactive {
                dataManager.stopAutoRefresh()
            }
        }
    }
}


