//
//  LinioApp.swift
//  Linio
//

import SwiftUI
import ActivityKit

// MARK: - App Delegate (für Background Task Registration)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // BGTask MUSS vor dem Ende von didFinishLaunchingWithOptions registriert werden
        if #available(iOS 16.2, *) {
            LiveActivityManager.registerBackgroundTask()
        }

        scheduleRenewalNotificationIfNeeded()

        // Konfiguration in DEBUG prüfen
        #if DEBUG
        let configErrors = AppConfiguration.validateConfiguration()
        for error in configErrors {
            print("⚠️ [CONFIG] \(error)")
        }
        #endif

        return true
    }

    // MARK: - Renewal Notification

    private func scheduleRenewalNotificationIfNeeded() {
        guard let json = UserDefaults.standard.string(forKey: "deutschlandTicketData"),
              let data = json.data(using: .utf8) else { return }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let ticket = try? dec.decode(DeutschlandTicket.self, from: data) else { return }
        Task { await TicketRenewalService.shared.scheduleRenewalNotification(for: ticket) }
    }

    // MARK: - Orientierung auf Portrait beschränken

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - App Entry Point

@main
struct LinioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var liveActivityManager = LiveActivityManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.systemDefault.rawValue

    init() {
        AppLocalization.apply()
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .environmentObject(liveActivityManager)
                    .id(appLanguage)
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .id(appLanguage)
            }
        }
    }
}
