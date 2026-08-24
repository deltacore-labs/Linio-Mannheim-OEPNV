//
//  WalkingNavigationView.swift
//  Linio
//
//  Zeigt den Fußweg zur Haltestelle mit Karte und Wegbeschreibung
//

import SwiftUI
import MapKit
import CoreLocation

struct WalkingNavigationView: View {
    let stopName: String
    let stopCoordinate: CLLocationCoordinate2D
    let departureTime: Date?
    
    @StateObject private var walkingService = WalkingRouteService.shared
    @ObservedObject var locationManager: LocationManager
    
    @State private var walkingRoute: WalkingRoute?
    @State private var mapRegion: MKCoordinateRegion?
    @State private var showFullMap = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    
    private let formatter = DateFormattingHelper.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.canvas.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Karten-Vorschau
                        mapPreviewSection
                        
                        // Weg-Info
                        if let route = walkingRoute {
                            routeInfoSection(route)
                        }
                        
                        // Abfahrtsinfo
                        if let departure = departureTime {
                            departureInfoSection(departure)
                        }
                        
                        // Aktionen
                        actionButtons
                        
                        Spacer(minLength: 30)
                    }
                    .padding()
                }
            }
            .navigationTitle("Fußweg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
        .task { await calculateRoute() }
        .sheet(isPresented: $showFullMap) {
            WalkingFullMapView(
                userLocation: locationManager.location,
                stopCoordinate: stopCoordinate,
                stopName: stopName,
                route: walkingRoute
            )
        }
    }
    
    // MARK: - Map Preview Section
    
    private var mapPreviewSection: some View {
        ZStack {
            if let region = mapRegion {
                Map(coordinateRegion: .constant(region), annotationItems: mapAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        annotationView(for: item)
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                )
                .onTapGesture {
                    HapticHelper.impact(.light)
                    showFullMap = true
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        HapticHelper.impact(.light)
                        showFullMap = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surfaceCard)
                    .frame(height: 200)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "map")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.muted)
                        }
                    }
            }
        }
    }
    
    private var mapAnnotations: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = []
        if let userLoc = locationManager.location {
            items.append(MapAnnotationItem(id: "user", coordinate: userLoc, type: .user))
        }
        items.append(MapAnnotationItem(id: "stop", coordinate: stopCoordinate, type: .stop))
        return items
    }
    
    @ViewBuilder
    private func annotationView(for item: MapAnnotationItem) -> some View {
        switch item.type {
        case .user:
            Circle()
                .fill(Color.blue)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2)
        case .stop:
            VStack(spacing: 2) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
    }
    
    // MARK: - Route Info Section
    
    private func routeInfoSection(_ route: WalkingRoute) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                infoCard(icon: "figure.walk", value: route.formattedDistance, label: "Entfernung", color: .blue)
                infoCard(icon: "clock", value: route.formattedWalkTime, label: "Gehzeit", color: .orange)
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ziel").font(.caption).foregroundColor(AppTheme.muted)
                    Text(stopName).font(.headline).foregroundColor(AppTheme.ink)
                }
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.hairline, lineWidth: 1)))
        }
    }
    
    private func infoCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title2.weight(.bold)).foregroundColor(AppTheme.ink)
            Text(label).font(.caption).foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceCard)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.hairline, lineWidth: 1)))
    }
    
    // MARK: - Departure Info Section
    
    private func departureInfoSection(_ departure: Date) -> some View {
        let isReachable = locationManager.location.map {
            walkingService.isDepartureReachable(userLocation: $0, stop: stopCoordinate, departureTime: departure)
        } ?? true
        
        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Abfahrt").font(.caption).foregroundColor(AppTheme.muted)
                    Text(formatter.formatTimeFromDate(departure)).font(.title2.weight(.bold)).foregroundColor(AppTheme.ink)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: isReachable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text(isReachable ? "Erreichbar" : "Knapp!")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(isReachable ? .green : .orange)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill((isReachable ? Color.green : Color.orange).opacity(0.15)))
            }
            
            if let userLoc = locationManager.location {
                let leaveTime = walkingService.calculateLeaveTime(userLocation: userLoc, stop: stopCoordinate, departureTime: departure)
                if leaveTime > Date() {
                    leaveTimeHint(time: leaveTime, urgent: false)
                } else {
                    leaveTimeHint(time: leaveTime, urgent: true)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceCard)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.hairline, lineWidth: 1)))
    }
    
    private func leaveTimeHint(time: Date, urgent: Bool) -> some View {
        HStack {
            Image(systemName: urgent ? "exclamationmark.triangle.fill" : "bell.fill")
                .foregroundColor(urgent ? .red : .blue)
            Text(urgent ? "Jetzt losgehen!" : "Losgehen um \(formatter.formatTimeFromDate(time))")
                .font(.subheadline.weight(urgent ? .semibold : .regular))
                .foregroundColor(urgent ? .red : AppTheme.bodyText)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill((urgent ? Color.red : Color.blue).opacity(0.1)))
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        Button {
            HapticHelper.impact(.medium)
            walkingService.openInAppleMaps(to: stopCoordinate, stopName: stopName)
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                Text("In Apple Maps öffnen")
            }
            .font(.headline)
            .foregroundColor(AppTheme.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Navigation in Apple Maps starten")
    }
    
    // MARK: - Route Calculation
    
    private func calculateRoute() async {
        guard let userLocation = locationManager.location else {
            errorMessage = "Standort nicht verfügbar"
            isLoading = false
            return
        }
        
        do {
            let route = try await walkingService.calculateRoute(from: userLocation, to: stopCoordinate, stopName: stopName)
            walkingRoute = route
            mapRegion = walkingService.regionForRoute(from: userLocation, to: stopCoordinate)
        } catch {
            errorMessage = error.localizedDescription
            mapRegion = walkingService.regionForRoute(from: userLocation, to: stopCoordinate)
        }
        isLoading = false
    }
}

// MARK: - Map Annotation Item

struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    
    enum AnnotationType { case user, stop }
}
