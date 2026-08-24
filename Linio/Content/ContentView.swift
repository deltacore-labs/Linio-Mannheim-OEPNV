//
//  ContentView.swift
//  Linio
//

import SwiftUI
import UIKit
import WidgetKit
import CoreLocation

struct ContentView: View {
    // Performance: @StateObject für Singletons verhindert unnötige Re-Initialisierungen
    @StateObject private var authService = AuthService.shared
    @StateObject private var graphQLService = GraphQLService.shared
    @StateObject private var locationManager = LocationManager()

    @State private var selectedTab = 0
    @State private var navigateToTrips = false

    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1) // #1c1917
                : UIColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1) // #f5f5f5
        }
        tabBarAppearance.shadowColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.267, green: 0.251, blue: 0.235, alpha: 1) // #44403c
                : UIColor(red: 0.906, green: 0.898, blue: 0.878, alpha: 1) // #e7e5e4
        }
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Connections Tab
            ConnectionsView(
                authService: authService,
                graphQLService: graphQLService,
                locationManager: locationManager
            )
            .tabItem {
                Label("Verbindungen", systemImage: "tram.fill")
            }
            .tag(0)

            // MARK: - Departure Board Tab
            DepartureBoardView(
                authService: authService,
                locationManager: locationManager,
                service: graphQLService
            )
            .tabItem {
                Label("Abfahrten", systemImage: "clock.fill")
            }
            .tag(1)

            // MARK: - Ticket Tab
            TicketView()
                .tabItem {
                    Label("Ticket", systemImage: "tram.card.fill")
                }
                .tag(2)

            // MARK: - Settings Tab
            SettingsView(locationManager: locationManager, navigateToTrips: $navigateToTrips)
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primaryColor)
        .dynamicTypeSize(.xSmall ... .accessibility2)
        .onOpenURL { url in
            // Dynamic Island / Live Activity deep link → Einstellungen (Fahrten-Abschnitt)
            if url.scheme == "rnv", url.host == "trips" {
                selectedTab = 3
                navigateToTrips = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTicketFullscreen)) { _ in
            selectedTab = 2
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "pendingShowTicketFullscreen") {
                selectedTab = 2
            }
            #if DEBUG
            print("🔍 [xcconfig] CLIENT_ID: \(Bundle.main.object(forInfoDictionaryKey: "RNV_CLIENT_ID") ?? "❌ NIL")")
            print("🔍 [xcconfig] GRAPHQL_URL: \(Bundle.main.object(forInfoDictionaryKey: "RNV_GRAPHQL_URL") ?? "❌ NIL")")
            #endif
        }
        .task {
            await authService.autoAuthenticate()
            WidgetCenter.shared.reloadTimelines(ofKind: "StationDepartureWidget")
            await locationManager.autoRequestLocation()
        }
        .task(id: "dailyCleanup") {
            // Einmaliger Cleanup beim Start – keine Endlosschleife nötig
            TripDataManager.shared.removeExpiredTrips()
        }
    }
}

// MARK: - App Theme

struct AppTheme {
    // Canvas & Surfaces (adaptive)
    static let canvas = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#1c1917") : UIColor(hex: "#f5f5f5")
    })
    static let canvasSoft     = Color(hex: "#fafafa")
    static let surfaceCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#292524") : .white
    })
    static let surfaceStrong = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#3c3836") : UIColor(hex: "#f0efed")
    })
    static let hairline = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#44403c") : UIColor(hex: "#e7e5e4")
    })
    static let hairlineStrong = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#57534e") : UIColor(hex: "#d6d3d1")
    })

    // Text (adaptive)
    static let ink = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? .white : UIColor(hex: "#0c0a09")
    })
    static let bodyText = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#c8c2bc") : UIColor(hex: "#4e4e4e")
    })
    static let muted = Color(UIColor { t in
        if t.accessibilityContrast == .high {
            return t.userInterfaceStyle == .dark ? UIColor(hex: "#c8c2bc") : UIColor(hex: "#565049")
        }
        return t.userInterfaceStyle == .dark ? UIColor(hex: "#a8a29e") : UIColor(hex: "#777169")
    })
    static let mutedSoft = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#a8a29e") : UIColor(hex: "#a8a29e")
    })

    // Actions (adaptive)
    static let primary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#e7e5e4") : UIColor(hex: "#292524")
    })
    static let primaryActive = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? .white : UIColor(hex: "#0c0a09")
    })
    static let primaryColor = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#e7e5e4") : UIColor(hex: "#292524")
    })
    static let onPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#1c1917") : .white
    })

    // Dark hero surfaces (always dark — not adaptive)
    static let surfaceDark         = Color(hex: "#0c0a09")
    static let surfaceDarkElevated = Color(hex: "#1c1917")
    static let onDark              = Color.white
    static let onDarkSoft          = Color(hex: "#a8a29e")

    // Atmospheric gradient orbs (decoration — no contrast requirement)
    static let gradientMint     = Color(hex: "#a7e5d3")
    static let gradientPeach    = Color(hex: "#f4c5a8")
    static let gradientLavender = Color(hex: "#c8b8e0")
    static let gradientSky      = Color(hex: "#a8c8e8")
    static let gradientRose     = Color(hex: "#e8b8c4")

    // Semantic (adaptive — WCAG AA compliant in dark mode; success passes AA for large text in light mode)
    static let semanticError = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#f87171") : UIColor(hex: "#dc2626")
    })
    static let semanticSuccess = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(hex: "#4ade80") : UIColor(hex: "#16a34a")
    })

    // Legacy aliases
    static let accentGradient   = LinearGradient(colors: [primary, primary], startPoint: .leading, endPoint: .trailing)
    static let headerBackground = LinearGradient(colors: [surfaceDark, surfaceDarkElevated], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardBackground   = surfaceCard
    static let subtleBackground = surfaceStrong
    static let secondaryColor   = primary

    // Shadow
    static func shadowColor(isPast: Bool = false) -> Color {
        Color.black.opacity(isPast ? 0.03 : 0.05)
    }

    // Typography
    static func displayFont(size: CGFloat) -> Font {
        .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: .light, design: .serif)
    }
    static let buttonFont = Font.system(size: 15, weight: .medium)
    static func monoFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: .monospaced)
    }

}

// MARK: - Color(hex:) initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, alpha: Double(a) / 255)
    }
}

#Preview {
    ContentView()
        .environmentObject(LiveActivityManager())
}
