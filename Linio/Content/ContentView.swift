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
        // Apple HIG: Verwende System Tab Bar Appearance für automatische Adaption
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
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
        .tint(Color.accentColor)
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

// MARK: - App Theme (HIG-konform, verweist auf Design System)
// DEPRECATED: Bitte direkt SemanticColor, Typography und DesignTokens verwenden.
// Diese Aliase existieren nur für Rückwärtskompatibilität.

struct AppTheme {
    // Canvas & Surfaces → HIG System Colors
    static var canvas: Color { SemanticColor.systemGroupedBackground }
    static var canvasSoft: Color { SemanticColor.systemBackground }
    static var surfaceCard: Color { SemanticColor.secondarySystemGroupedBackground }
    static var surfaceStrong: Color { SemanticColor.tertiarySystemFill }
    static var hairline: Color { SemanticColor.separator }
    static var hairlineStrong: Color { SemanticColor.opaqueSeparator }

    // Text → HIG Label Colors
    static var ink: Color { SemanticColor.label }
    static var bodyText: Color { SemanticColor.secondaryLabel }
    static var muted: Color { SemanticColor.secondaryLabel }
    static var mutedSoft: Color { SemanticColor.tertiaryLabel }

    // Actions → HIG System Colors
    static var primary: Color { Color.accentColor }
    static var primaryActive: Color { SemanticColor.label }
    static var primaryColor: Color { Color.accentColor }
    static var onPrimary: Color { Color.white }

    // Dark hero surfaces (für spezielle Header-Bereiche)
    static let surfaceDark = Color(UIColor.systemGray6.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
    static let surfaceDarkElevated = Color(UIColor.secondarySystemBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
    static var onDark: Color { Color.white }
    static var onDarkSoft: Color { SemanticColor.tertiaryLabel }

    // Atmospheric gradient orbs → HIG System Colors (subtile Varianten)
    static var gradientMint: Color { SemanticColor.systemTeal }
    static var gradientPeach: Color { SemanticColor.systemOrange }
    static var gradientLavender: Color { SemanticColor.systemIndigo }
    static var gradientSky: Color { SemanticColor.systemCyan }
    static var gradientRose: Color { SemanticColor.systemPink }

    // Semantic → HIG System Colors
    static var semanticError: Color { SemanticColor.systemRed }
    static var semanticSuccess: Color { SemanticColor.systemGreen }

    // Legacy aliases
    static var accentGradient: LinearGradient { LinearGradient(colors: [primary, primary], startPoint: .leading, endPoint: .trailing) }
    static var headerBackground: LinearGradient { LinearGradient(colors: [surfaceDark, surfaceDarkElevated], startPoint: .topLeading, endPoint: .bottomTrailing) }
    static var cardBackground: Color { surfaceCard }
    static var subtleBackground: Color { surfaceStrong }
    static var secondaryColor: Color { primary }

    // Shadow → DesignTokens
    static func shadowColor(isPast: Bool = false) -> Color {
        isPast ? .clear : DesignTokens.Shadow.small.color
    }

    // Typography → San Francisco System
    static func displayFont(size: CGFloat) -> Font {
        Typography.display(size: size, weight: .light)
    }
    static var buttonFont: Font { Typography.body.weight(.semibold) }
    static func monoFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Typography.mono(size: size, weight: weight)
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
