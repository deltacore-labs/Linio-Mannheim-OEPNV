//
//  NearbyStationButton.swift
//  Linio
//
//  GPS-basierter Schnellzugriff: nächstgelegene Haltestelle sofort öffnen
//

import SwiftUI
import CoreLocation

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
        
        if locationManager.location == nil {
            locationManager.startLocationUpdates()
            // Warte kurz auf Standort
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard locationManager.location != nil else {
                errorMessage = "Standort nicht verfügbar. Bitte Standortzugriff erlauben."
                showError = true
                HapticHelper.notification(.warning)
                return
            }
        }
        
        guard let currentLocation = locationManager.location else {
            errorMessage = "Standort konnte nicht ermittelt werden"
            showError = true
            HapticHelper.notification(.warning)
            return
        }
        
        // Token sicherstellen
        if !authService.isTokenValid {
            await authService.autoAuthenticate()
        }
        
        guard let token = authService.accessToken, !token.isEmpty else {
            errorMessage = "Authentifizierung fehlgeschlagen"
            showError = true
            HapticHelper.notification(.error)
            return
        }
        
        // Stationen in der Nähe laden
        await graphQLService.searchStations(
            lat: currentLocation.latitude,
            lon: currentLocation.longitude,
            accessToken: token
        )
        
        // Nächste Station finden
        guard let nearest = graphQLService.stations.first else {
            errorMessage = "Keine Haltestellen in der Nähe gefunden"
            showError = true
            HapticHelper.notification(.warning)
            return
        }
        
        HapticHelper.impact(.medium)
        onStationSelected(nearest)
    }
}

// MARK: - Kompakte Version für Header

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
                    ProgressView()
                        .scaleEffect(0.65)
                        .tint(AppTheme.primaryColor)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                Text("In der Nähe")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(AppTheme.primaryColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(AppTheme.primaryColor.opacity(0.1))
            )
        }
        .disabled(isLoading)
    }
    
    private func findNearestStation() async {
        if locationManager.location == nil {
            locationManager.startLocationUpdates()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard locationManager.location != nil else { return }
        }
        
        guard let currentLocation = locationManager.location else { return }
        
        isLoading = true
        HapticHelper.impact(.light)
        defer { isLoading = false }
        
        if !authService.isTokenValid {
            await authService.autoAuthenticate()
        }
        
        guard let token = authService.accessToken, !token.isEmpty else { return }
        
        await graphQLService.searchStations(
            lat: currentLocation.latitude,
            lon: currentLocation.longitude,
            accessToken: token
        )
        
        guard let nearest = graphQLService.stations.first else { return }
        
        HapticHelper.impact(.medium)
        onStationSelected(nearest)
    }
}
