// WatchLocationManager.swift
// Standortdienste für die Apple Watch

import Foundation
import CoreLocation
import Combine

@MainActor
class WatchLocationManager: NSObject, ObservableObject {
    static let shared = WatchLocationManager()

    @Published var location: CLLocationCoordinate2D?
    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        checkAuthorization()
    }

    private func checkAuthorization() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = false
        default:
            isAuthorized = false
        }
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Fordert einmalig den aktuellen Standort an
    func requestLocation() async -> CLLocationCoordinate2D? {
        if manager.authorizationStatus == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                self.authorizationContinuation = continuation
                self.requestAuthorization()
            }
            if !granted {
                errorMessage = "Standortzugriff nicht erlaubt"
                return nil
            }
        }

        guard isAuthorized else {
            errorMessage = "Standortzugriff nicht erlaubt"
            return nil
        }

        isLoading = true
        errorMessage = nil

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()

            // Timeout nach 10 Sekunden
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if self.locationContinuation != nil {
                    self.locationContinuation?.resume(returning: nil)
                    self.locationContinuation = nil
                    self.isLoading = false
                    self.errorMessage = "Standort-Timeout"
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WatchLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.location = loc.coordinate
            self.isLoading = false
            self.locationContinuation?.resume(returning: loc.coordinate)
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = "Standortfehler: \(error.localizedDescription)"
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let granted: Bool
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.isAuthorized = true
                granted = true
            default:
                self.isAuthorized = false
                granted = false
            }
            self.authorizationContinuation?.resume(returning: granted)
            self.authorizationContinuation = nil
        }
    }
}
