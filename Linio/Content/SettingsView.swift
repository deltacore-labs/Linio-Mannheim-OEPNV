//
//  SettingsView.swift
//  Linio
//

import SwiftUI
import CoreLocation
import UserNotifications

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var navigateToTrips: Bool
    @EnvironmentObject var liveActivityManager: LiveActivityManager
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("autoStartLiveActivity") private var autoStartLiveActivity = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("defaultSearchRadius") private var defaultSearchRadius = 2.0
    @AppStorage("maxConnections") private var maxConnections = 5
    @AppStorage("enableTram") private var enableTram = true
    @AppStorage("enableBus") private var enableBus = true
    @AppStorage("enableSBahn") private var enableSBahn = true
    @AppStorage("developerMode") private var developerMode = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 10

    @State private var showingResetAlert = false
    @State private var showingCleanupSuccess = false
    @State private var showingCacheSuccess = false
    @State private var showPrivacyPolicy = false
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showFavoritesManagement = false
    @State private var showWalletDebugLogs = false
    
    // Performance: @StateObject für Singleton
    @StateObject private var favoritesManager = FavoriteStationsManager.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }
    
    /// Erkennt ob die App über TestFlight installiert wurde (nicht App Store)
    private var isTestFlight: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }

    private var notificationsDenied: Bool { notificationAuthStatus == .denied }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    appHeader
                    tripsSection
                    favoritesSection
                    searchSection
                    transportSection
                    notificationSection
                    locationSection
                    appSection
                    
                    // Wallet Debug nur für TestFlight (interne Tests), nicht im App Store
                    if isTestFlight {
                        walletDebugSection
                    }
                    
                    #if DEBUG
                    developerSection
                    #endif
                    footerSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .background(AppTheme.canvas.ignoresSafeArea())
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
            .alert("Alle Activities beenden?", isPresented: $showingResetAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Beenden", role: .destructive) {
                    Task {
                        await cleanupAllActivities()
                        showingCleanupSuccess = true
                    }
                }
            } message: {
                Text("Alle aktiven Live Activities werden beendet und die Toggles zurückgesetzt.")
            }
            .alert("Erfolgreich", isPresented: $showingCleanupSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Alle Live Activities wurden beendet.")
            }
            .alert("Cache geleert", isPresented: $showingCacheSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Der gespeicherte Suchverlauf wurde gelöscht.")
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .onChange(of: reminderMinutes) { rescheduleAllNotifications() }
            .task(id: scenePhase) {
                if scenePhase == .active {
                    notificationAuthStatus = await NotificationService.shared.authorizationStatus()
                }
            }
            .navigationDestination(isPresented: $navigateToTrips) {
                PlannedTripsView().environmentObject(liveActivityManager)
            }
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.surfaceDark, AppTheme.surfaceDarkElevated],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)

                Image(systemName: "tram.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .shadow(color: AppTheme.surfaceDark.opacity(0.25), radius: 10, x: 0, y: 4)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("ÖPNV Mannheim")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.ink)

                HStack(spacing: 6) {
                    Text("v\(appVersion)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.onDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.surfaceDark.opacity(0.85))
                        .clipShape(Capsule())

                    Text("Mannheim & Umgebung")
                        .font(.caption)
                        .foregroundColor(AppTheme.muted)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ÖPNV Mannheim, Version \(appVersion), Mannheim & Umgebung")
    }

    // MARK: - Trips Section

    private var tripsSection: some View {
        SettingsCard(title: "Geplante Fahrten", icon: "bell.fill", iconColor: AppTheme.primaryColor, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            Button { navigateToTrips = true } label: {
                HStack(spacing: 12) {
                    IconBadge(icon: "bell.fill", color: AppTheme.primaryColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fahrten & Archiv")
                            .font(.body)
                            .foregroundColor(AppTheme.ink)
                        Text("Aktive Live Activities und Fahrtenverlauf")
                            .font(.caption)
                            .foregroundColor(AppTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.mutedSoft)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        SettingsCard(title: "Favoriten-Haltestellen", icon: "star.fill", iconColor: .yellow, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            if favoritesManager.favorites.isEmpty {
                HStack(spacing: 12) {
                    IconBadge(icon: "star", color: .yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keine Favoriten")
                            .font(.body)
                            .foregroundColor(AppTheme.ink)
                        Text("Füge Haltestellen als Favoriten hinzu für schnellen Zugriff")
                            .font(.caption)
                            .foregroundColor(AppTheme.muted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                ForEach(favoritesManager.favorites) { favorite in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(favorite.iconColor.opacity(0.14))
                                .frame(width: 32, height: 32)
                            Image(systemName: favorite.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(favorite.iconColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(favorite.station.longName)
                                .font(.body)
                                .foregroundColor(AppTheme.ink)
                                .lineLimit(1)
                            Text(favorite.displayLabel)
                                .font(.caption)
                                .foregroundColor(favorite.iconColor)
                        }
                        Spacer()
                        Button {
                            favoritesManager.removeFavorite(id: favorite.id)
                            HapticHelper.impact(.light)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.mutedSoft)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    
                    if favorite.id != favoritesManager.favorites.last?.id {
                        RowDivider(color: AppTheme.hairline)
                    }
                }
            }
            
            if !favoritesManager.favorites.isEmpty {
                RowDivider(color: AppTheme.hairline)
                
                HStack(spacing: 12) {
                    IconBadge(icon: "info.circle", color: AppTheme.muted)
                    Text("\(favoritesManager.remainingSlots) Plätze verfügbar")
                        .font(.caption)
                        .foregroundColor(AppTheme.muted)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        SettingsCard(title: "Verbindungssuche", icon: "magnifyingglass", iconColor: AppTheme.primaryColor, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            HStack(spacing: 12) {
                IconBadge(icon: "list.number", color: AppTheme.primaryColor)
                Text("Max. Verbindungen")
                    .font(.body)
                    .foregroundColor(AppTheme.ink)
                Spacer()
                CounterControl(value: $maxConnections, range: 3...10, tint: AppTheme.primaryColor, label: "Maximale Verbindungen")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            RowDivider(color: AppTheme.hairline)

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    IconBadge(icon: "scope", color: AppTheme.primaryColor)
                    Text("Suchradius")
                        .font(.body)
                        .foregroundColor(AppTheme.ink)
                    Spacer()
                    Text("\(String(format: "%.1f", defaultSearchRadius)) km")
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppTheme.primaryColor)
                        .monospacedDigit()
                }
                Slider(value: $defaultSearchRadius, in: 0.5...5.0, step: 0.5)
                    .tint(AppTheme.primaryColor)
                    .padding(.leading, 44)
                    .accessibilityLabel("Suchradius")
                    .accessibilityValue("\(String(format: "%.1f", defaultSearchRadius)) Kilometer")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

        }
    }

    // MARK: - Transport Section

    private var transportSection: some View {
        SettingsCard(title: "Verkehrsmittel", icon: "tram.fill", iconColor: .red, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            ToggleRow(title: "Straßenbahn", icon: "tram.fill", iconColor: .red, binding: $enableTram)
            RowDivider(color: AppTheme.hairline)
            ToggleRow(title: "Bus", icon: "bus.fill", iconColor: .blue, binding: $enableBus)
            RowDivider(color: AppTheme.hairline)
            ToggleRow(title: "S-Bahn", icon: "train.side.front.car", iconColor: .green, binding: $enableSBahn)
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        SettingsCard(title: "Live Activity & Mitteilungen", icon: "bell.badge.fill", iconColor: .orange, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            ToggleRow(
                title: "Automatisch starten",
                subtitle: "Bei jeder Verbindungssuche",
                icon: "livephoto",
                iconColor: AppTheme.primaryColor,
                binding: $autoStartLiveActivity
            )
            RowDivider(color: AppTheme.hairline)
            VStack(spacing: 0) {
                ToggleRow(
                    title: "Push-Benachrichtigungen",
                    subtitle: "Verspätungen und Änderungen",
                    icon: "bell.fill",
                    iconColor: .orange,
                    binding: $notificationsEnabled
                )
                RowDivider(color: AppTheme.hairline)
                HStack(spacing: 12) {
                    IconBadge(icon: "timer", color: .orange)
                    Text("Erinnerung")
                        .font(.body)
                        .foregroundColor(AppTheme.ink)
                    Spacer()
                    Picker("", selection: $reminderMinutes) {
                        ForEach([5, 10, 15, 20, 30], id: \.self) { min in
                            Text("\(min) Min").tag(min)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.primaryColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .disabled(notificationsDenied)
            RowDivider(color: AppTheme.hairline)
            ActionRow(
                title: notificationsDenied
                    ? "Benachrichtigungen in Einstellungen erlauben"
                    : "Systemeinstellungen öffnen",
                icon: "arrow.up.right.square",
                iconColor: notificationsDenied ? AppTheme.primaryColor : AppTheme.muted,
                inkColor: notificationsDenied ? AppTheme.primaryColor : AppTheme.ink,
                showChevron: false,
                action: openSystemSettings
            )
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        SettingsCard(title: "Standort", icon: "location.fill", iconColor: AppTheme.primaryColor, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            HStack(spacing: 12) {
                IconBadge(icon: "location.fill", color: AppTheme.primaryColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Aktueller Standort")
                        .font(.body)
                        .foregroundColor(AppTheme.ink)
                    locationStatusText
                }
                Spacer()
                if locationManager.isLocating {
                    ProgressView().scaleEffect(0.8)
                } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                    Button {
                        locationManager.startLocationUpdates()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.primaryColor)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.primaryColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Standort aktualisieren")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                RowDivider(color: AppTheme.hairline)
                ActionRow(
                    title: "Standortzugriff in Einstellungen erlauben",
                    icon: "arrow.up.right.square",
                    iconColor: AppTheme.primaryColor,
                    inkColor: AppTheme.primaryColor,
                    showChevron: false,
                    action: openSystemSettings
                )
            }
        }
    }

    @ViewBuilder
    private var locationStatusText: some View {
        switch locationManager.authorizationStatus {
        case .denied:
            Text("Zugriff verweigert")
                .font(.caption)
                .foregroundColor(AppTheme.semanticError)
        case .restricted:
            Text("Eingeschränkt")
                .font(.caption)
                .foregroundColor(.orange)
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = locationManager.location {
                Text("\(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(AppTheme.muted)
                    .accessibilityLabel("Koordinaten: \(String(format: "%.4f", location.latitude)) nördlich, \(String(format: "%.4f", location.longitude)) östlich")
            } else {
                Text("Wird ermittelt …")
                    .font(.caption)
                    .foregroundColor(AppTheme.muted)
            }
        default:
            Text("Nicht verfügbar")
                .font(.caption)
                .foregroundColor(AppTheme.muted)
        }
    }

    // MARK: - App Section (Daten & Datenschutz)

    private var appSection: some View {
        SettingsCard(title: "App & Daten", icon: "externaldrive.fill", iconColor: AppTheme.muted, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            ActionRow(
                title: "Cache leeren",
                icon: "arrow.clockwise",
                iconColor: AppTheme.primaryColor,
                inkColor: AppTheme.ink,
                showChevron: false
            ) {
                clearCache()
                showingCacheSuccess = true
            }
            RowDivider(color: AppTheme.hairline)
            ActionRow(
                title: "Alle Live Activities beenden",
                icon: "xmark.circle.fill",
                iconColor: AppTheme.semanticError,
                inkColor: AppTheme.semanticError,
                showChevron: false
            ) {
                showingResetAlert = true
            }
            RowDivider(color: AppTheme.hairline)
            ActionRow(
                title: "Datenschutzerklärung",
                icon: "lock.shield.fill",
                iconColor: .blue,
                inkColor: AppTheme.ink
            ) {
                showPrivacyPolicy = true
            }
        }
    }

    // MARK: - Wallet Debug Section (TestFlight)
    
    private var walletDebugSection: some View {
        SettingsCard(title: "Wallet Debug", icon: "wallet.pass.fill", iconColor: .purple, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            ActionRow(
                title: "Debug-Logs anzeigen",
                icon: "doc.text.magnifyingglass",
                iconColor: .purple,
                inkColor: AppTheme.ink
            ) {
                showWalletDebugLogs = true
            }
            RowDivider(color: AppTheme.hairline)
            ActionRow(
                title: "Logs teilen",
                icon: "square.and.arrow.up",
                iconColor: .blue,
                inkColor: AppTheme.ink,
                showChevron: false
            ) {
                shareWalletLogs()
            }
            RowDivider(color: AppTheme.hairline)
            ActionRow(
                title: "Logs löschen",
                icon: "trash",
                iconColor: AppTheme.semanticError,
                inkColor: AppTheme.semanticError,
                showChevron: false
            ) {
                WalletDebugLogger.shared.clearLogs()
            }
        }
        .sheet(isPresented: $showWalletDebugLogs) {
            WalletDebugLogsView()
        }
    }
    
    private func shareWalletLogs() {
        let logText = WalletDebugLogger.shared.getLogsAsText()
        let av = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    // MARK: - Developer Section

    private var developerSection: some View {
        SettingsCard(title: "Entwickler", icon: "hammer.fill", iconColor: developerMode ? .orange : AppTheme.muted, cardBg: AppTheme.surfaceCard, dividerColor: AppTheme.hairline) {
            ToggleRow(
                title: "Entwicklermodus",
                icon: "hammer.fill",
                iconColor: developerMode ? .orange : AppTheme.muted,
                binding: $developerMode
            )
            if developerMode {
                RowDivider(color: AppTheme.hairline)
                ActionRow(title: "Mannheim Hbf (Test)", icon: "mappin.circle.fill", iconColor: .orange, inkColor: AppTheme.ink, showChevron: false) {
                    locationManager.location = CLLocationCoordinate2D(latitude: 49.483076, longitude: 8.468409)
                }
                RowDivider(color: AppTheme.hairline)
                ActionRow(title: "Heidelberg Hbf (Test)", icon: "mappin.circle.fill", iconColor: .purple, inkColor: AppTheme.ink, showChevron: false) {
                    locationManager.location = CLLocationCoordinate2D(latitude: 49.4044, longitude: 8.6765)
                }
                RowDivider(color: AppTheme.hairline)
                ActionRow(title: "Debug: State ausgeben", icon: "ant.fill", iconColor: AppTheme.semanticError, inkColor: AppTheme.ink, showChevron: false) {
                    LiveActivityState.shared.debugPrintState()
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 10) {
            Text("Studentenprojekt – nicht verbunden mit der rnv GmbH oder anderen Verkehrsbetrieben.")
                .font(.caption)
                .foregroundColor(AppTheme.muted)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Label("v\(appVersion)", systemImage: "checkmark.seal")
                Text("·")
                Label("Öffentliche Daten", systemImage: "network")
                Text("·")
                Label("Mannheim", systemImage: "mappin")
            }
            .font(.caption2)
            .foregroundColor(AppTheme.mutedSoft)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    // MARK: - Private Methods

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: "recentStations")
        #if DEBUG
        print("🗑️ [SETTINGS] Cache geleert")
        #endif
    }

    private func cleanupAllActivities() async {
        if #available(iOS 16.2, *) {
            #if DEBUG
            print("🗑️ [SETTINGS] Beende alle Live Activities...")
            #endif
            await liveActivityManager.endAllActivitiesAndResetToggles()
            LiveActivityState.shared.deactivateAllTrips()
            #if DEBUG
            print("✅ [SETTINGS] Live Activities beendet")
            #endif
        }
    }

    private func rescheduleAllNotifications() {
        NotificationService.shared.cancelAll()
        let trips = TripDataManager.shared.getAllTrips()
        for trip in trips where trip.notificationsEnabled {
            NotificationService.shared.schedule(trip: trip, minutesBefore: reminderMinutes)
        }
    }
}

// MARK: - Subcomponents

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let cardBg: Color
    let dividerColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
                Text(LocalizedStringKey(title))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.muted)
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}

private struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    let icon: String
    let iconColor: Color
    @Binding var binding: Bool

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.body)
                    .foregroundColor(AppTheme.ink)
                if let sub = subtitle {
                    Text(LocalizedStringKey(sub))
                        .font(.caption)
                        .foregroundColor(AppTheme.muted)
                }
            }
            Spacer()
            Toggle("", isOn: $binding)
                .tint(AppTheme.primaryColor)
                .labelsHidden()
                .accessibilityLabel(title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ActionRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let inkColor: Color
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconBadge(icon: icon, color: iconColor)
                Text(LocalizedStringKey(title))
                    .font(.body)
                    .foregroundColor(inkColor)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.mutedSoft)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

private struct IconBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.14))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .accessibilityHidden(true)
    }
}

private struct CounterControl: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let tint: Color
    var label: String = "Wert"

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if value > range.lowerBound { value -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(value > range.lowerBound ? tint : AppTheme.mutedSoft)
                    .frame(width: 28, height: 28)
                    .background((value > range.lowerBound ? tint : AppTheme.mutedSoft).opacity(0.12))
                    .clipShape(Circle())
            }
            .disabled(value <= range.lowerBound)
            .accessibilityLabel("\(label) verringern")

            Text("\(value)")
                .font(.body.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 20, alignment: .center)
                .accessibilityHidden(true)

            Button {
                if value < range.upperBound { value += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(value < range.upperBound ? tint : AppTheme.mutedSoft)
                    .frame(width: 28, height: 28)
                    .background((value < range.upperBound ? tint : AppTheme.mutedSoft).opacity(0.12))
                    .clipShape(Circle())
            }
            .disabled(value >= range.upperBound)
            .accessibilityLabel("\(label) erhöhen")
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(value)")
    }
}

private struct RowDivider: View {
    let color: Color
    var body: some View {
        color
            .frame(height: 0.5)
            .padding(.leading, 60)
    }
}

#Preview {
    SettingsView(locationManager: LocationManager(), navigateToTrips: .constant(false))
        .environmentObject(LiveActivityManager())
}
