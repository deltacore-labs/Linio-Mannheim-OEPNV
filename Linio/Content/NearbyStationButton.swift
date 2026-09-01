//
//  NearbyStationButton.swift
//  Linio
//
//  GPS-basierter Schnellzugriff: nächstgelegene Haltestelle sofort öffnen
//

import SwiftUI
import CoreLocation

// MARK: - Gemeinsame Such-Logik

enum NearbyStationFinder {
    enum Result { case success(Station), locationUnavailable, authFailed, noStationsFound }
    
    static func find(locationManager: LocationManager, graphQLService: GraphQLService, authService: AuthService) async -> Result {
        if locationManager.location == nil {
            locationManager.startLocationUpdates()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
        }
        guard let loc = locationManager.location else { return .locationUnavailable }
        guard let token = await authService.ensureValidToken(), !token.isEmpty else { return .authFailed }
        await graphQLService.searchStations(lat: loc.latitude, lon: loc.longitude, accessToken: token)
        guard let nearest = graphQLService.stations.first else { return .noStationsFound }
        return .success(nearest)
    }
}

// MARK: - Hauptbutton

struct NearbyStationButton: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var graphQLService: GraphQLService
    @ObservedObject var authService: AuthService
    let onStationSelected: (Station) -> Void
    
    @State private var isLoading = false
    @State private var nearestStation: Station?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        Button {
            Task { await findNearestStation() }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text("Jetzt in der Nähe")
                    .font(AppTheme.buttonFont)
            }
            .foregroundColor(isLoading ? .white.opacity(0.7) : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.primaryColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isLoading)
        .accessibilityLabel("Nächste Haltestelle finden")
        .accessibilityHint("Sucht die nächstgelegene Haltestelle basierend auf deinem Standort")
        .alert("Standortsuche", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Ein Fehler ist aufgetreten")
        }
    }
    
    private func findNearestStation() async {
        isLoading = true
        HapticHelper.impact(.light)
        defer { isLoading = false }
        
        let result = await NearbyStationFinder.find(locationManager: locationManager, graphQLService: graphQLService, authService: authService)
        switch result {
        case .success(let station):
            HapticHelper.impact(.medium)
            onStationSelected(station)
        case .locationUnavailable:
            errorMessage = "Standort nicht verfügbar. Bitte Standortzugriff erlauben."
            showError = true; HapticHelper.notification(.warning)
        case .authFailed:
            errorMessage = "Authentifizierung fehlgeschlagen"
            showError = true; HapticHelper.notification(.error)
        case .noStationsFound:
            errorMessage = "Keine Haltestellen in der Nähe gefunden"
            showError = true; HapticHelper.notification(.warning)
        }
    }
}

// MARK: - Kompakte Version

struct NearbyStationCompactButton: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var graphQLService: GraphQLService
    @ObservedObject var authService: AuthService
    let onStationSelected: (Station) -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        Button {
            Task { await findNearestStation() }
        } label: {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView().scaleEffect(0.65).tint(AppTheme.primaryColor)
                } else {
                    Image(systemName: "location.fill").font(.system(size: 11, weight: .semibold))
                }
                Text("In der Nähe").font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(AppTheme.primaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppTheme.primaryColor.opacity(0.1)))
        }
        .disabled(isLoading)
    }
    
    private func findNearestStation() async {
        isLoading = true
        HapticHelper.impact(.light)
        defer { isLoading = false }
        
        if case .success(let station) = await NearbyStationFinder.find(locationManager: locationManager, graphQLService: graphQLService, authService: authService) {
            HapticHelper.impact(.medium)
            onStationSelected(station)
        }
    }
}
