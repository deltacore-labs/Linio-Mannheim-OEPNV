//
//  WalkingRouteService.swift
//  Linio
//
//  Service für Fußweg-Berechnungen zur Haltestelle
//

import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Walking Route Model

struct WalkingRoute: Identifiable, Equatable {
    let id = UUID()
    let destination: CLLocationCoordinate2D
    let destinationName: String
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    let route: MKRoute?
    let polyline: MKPolyline?
    
    var formattedDistance: String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000).replacingOccurrences(of: ".", with: ",")
        }
    }
    
    var formattedWalkTime: String {
        "\(Int(ceil(expectedTravelTime / 60))) min"
    }
    
    func estimatedArrivalTime(from startTime: Date = Date()) -> Date {
        startTime.addingTimeInterval(expectedTravelTime)
    }
    
    static func == (lhs: WalkingRoute, rhs: WalkingRoute) -> Bool { lhs.id == rhs.id }
}

// MARK: - Walking Route Error

enum WalkingRouteError: LocalizedError {
    case locationNotAvailable
    case destinationNotFound
    case routeCalculationFailed(String)
    case noRouteFound
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable: return "Standort nicht verfügbar."
        case .destinationNotFound: return "Ziel nicht gefunden."
        case .routeCalculationFailed(let reason): return "Route-Berechnung fehlgeschlagen: \(reason)"
        case .noRouteFound: return "Kein Fußweg gefunden."
        }
    }
}

// MARK: - Walking Route Service

@MainActor
final class WalkingRouteService: ObservableObject {
    static let shared = WalkingRouteService()
    
    @Published var currentRoute: WalkingRoute?
    @Published var isCalculating = false
    @Published var lastError: WalkingRouteError?
    
    private let averageWalkingSpeed: Double = 1.4 // m/s (~5 km/h)
    private let safetyBuffer: TimeInterval = 60
    
    private init() {}
    
    func calculateRoute(
        from userLocation: CLLocationCoordinate2D,
        to stopCoordinate: CLLocationCoordinate2D,
        stopName: String
    ) async throws -> WalkingRoute {
        isCalculating = true
        lastError = nil
        defer { isCalculating = false }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: stopCoordinate))
        request.transportType = .walking
        
        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else { throw WalkingRouteError.noRouteFound }
            
            let walkingRoute = WalkingRoute(
                destination: stopCoordinate,
                destinationName: stopName,
                distance: route.distance,
                expectedTravelTime: route.expectedTravelTime + safetyBuffer,
                route: route,
                polyline: route.polyline
            )
            self.currentRoute = walkingRoute
            return walkingRoute
        } catch let error as WalkingRouteError {
            self.lastError = error
            throw error
        } catch {
            let routeError = WalkingRouteError.routeCalculationFailed(error.localizedDescription)
            self.lastError = routeError
            throw routeError
        }
    }
    
    func estimateWalkTime(from userLocation: CLLocationCoordinate2D, to stop: CLLocationCoordinate2D) -> TimeInterval {
        let distance = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            .distance(from: CLLocation(latitude: stop.latitude, longitude: stop.longitude)) * 1.3
        return (distance / averageWalkingSpeed) + safetyBuffer
    }
    
    func isDepartureReachable(userLocation: CLLocationCoordinate2D, stop: CLLocationCoordinate2D, departureTime: Date) -> Bool {
        Date().addingTimeInterval(estimateWalkTime(from: userLocation, to: stop)) < departureTime
    }
    
    func calculateLeaveTime(userLocation: CLLocationCoordinate2D, stop: CLLocationCoordinate2D, departureTime: Date) -> Date {
        departureTime.addingTimeInterval(-estimateWalkTime(from: userLocation, to: stop))
    }
    
    func regionForRoute(from user: CLLocationCoordinate2D, to stop: CLLocationCoordinate2D, padding: Double = 1.5) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (user.latitude + stop.latitude) / 2, longitude: (user.longitude + stop.longitude) / 2),
            span: MKCoordinateSpan(latitudeDelta: max(abs(user.latitude - stop.latitude) * padding, 0.005),
                                   longitudeDelta: max(abs(user.longitude - stop.longitude) * padding, 0.005))
        )
    }
    
    func openInAppleMaps(to stop: CLLocationCoordinate2D, stopName: String) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: stop))
        destination.name = stopName
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
