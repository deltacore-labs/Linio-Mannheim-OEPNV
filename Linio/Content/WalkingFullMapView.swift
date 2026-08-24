//
//  WalkingFullMapView.swift
//  Linio
//
//  Vollbild-Karte für Fußweg-Navigation
//

import SwiftUI
import MapKit
import CoreLocation

struct WalkingFullMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let stopCoordinate: CLLocationCoordinate2D
    let stopName: String
    let route: WalkingRoute?
    
    @State private var mapRegion: MKCoordinateRegion
    @State private var showUserLocation = true
    @Environment(\.dismiss) private var dismiss
    
    init(userLocation: CLLocationCoordinate2D?, stopCoordinate: CLLocationCoordinate2D, stopName: String, route: WalkingRoute?) {
        self.userLocation = userLocation
        self.stopCoordinate = stopCoordinate
        self.stopName = stopName
        self.route = route
        
        let center = userLocation.map {
            CLLocationCoordinate2D(latitude: ($0.latitude + stopCoordinate.latitude) / 2,
                                   longitude: ($0.longitude + stopCoordinate.longitude) / 2)
        } ?? stopCoordinate
        
        let span = userLocation.map {
            MKCoordinateSpan(latitudeDelta: max(abs($0.latitude - stopCoordinate.latitude) * 1.5, 0.01),
                            longitudeDelta: max(abs($0.longitude - stopCoordinate.longitude) * 1.5, 0.01))
        } ?? MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        _mapRegion = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $mapRegion, showsUserLocation: showUserLocation, annotationItems: annotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        stopAnnotation
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // Overlay Controls
                VStack {
                    Spacer()
                    controlsOverlay
                }
            }
            .navigationTitle("Karte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
    
    private var annotations: [StopAnnotation] {
        [StopAnnotation(id: "stop", coordinate: stopCoordinate, name: stopName)]
    }
    
    private var stopAnnotation: some View {
        VStack(spacing: 4) {
            Image(systemName: "tram.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(AppTheme.primary))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            
            Text(stopName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(AppTheme.ink)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(AppTheme.surfaceCard).shadow(radius: 2))
                .lineLimit(1)
        }
    }
    
    private var controlsOverlay: some View {
        HStack(spacing: 12) {
            // Route Info
            if let route = route {
                HStack(spacing: 16) {
                    Label(route.formattedDistance, systemImage: "figure.walk")
                    Label(route.formattedWalkTime, systemImage: "clock")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceCard).shadow(radius: 4))
            }
            
            Spacer()
            
            // Apple Maps Button
            Button {
                HapticHelper.impact(.medium)
                WalkingRouteService.shared.openInAppleMaps(to: stopCoordinate, stopName: stopName)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 4)
            }
        }
        .padding()
    }
}

// MARK: - Stop Annotation

private struct StopAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let name: String
}
