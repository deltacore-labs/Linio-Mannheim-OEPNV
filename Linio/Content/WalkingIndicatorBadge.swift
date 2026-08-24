//
//  WalkingIndicatorBadge.swift
//  Linio
//
//  Kompakte Fußweg-Anzeige für Verbindungs- und Abfahrtskarten
//

import SwiftUI
import CoreLocation

struct WalkingIndicatorBadge: View {
    let userLocation: CLLocationCoordinate2D?
    let stopCoordinate: CLLocationCoordinate2D
    let stopName: String
    let departureTime: Date?
    let compact: Bool
    
    @ObservedObject var locationManager: LocationManager
    @State private var walkTime: TimeInterval?
    @State private var showNavigationSheet = false
    
    private let walkingService = WalkingRouteService.shared
    
    init(userLocation: CLLocationCoordinate2D?, stopCoordinate: CLLocationCoordinate2D, stopName: String,
         departureTime: Date? = nil, compact: Bool = true, locationManager: LocationManager) {
        self.userLocation = userLocation
        self.stopCoordinate = stopCoordinate
        self.stopName = stopName
        self.departureTime = departureTime
        self.compact = compact
        self.locationManager = locationManager
    }
    
    var body: some View {
        if let userLoc = userLocation ?? locationManager.location {
            Button {
                HapticHelper.selection()
                showNavigationSheet = true
            } label: {
                badgeContent(userLocation: userLoc)
            }
            .buttonStyle(.plain)
            .onAppear { walkTime = walkingService.estimateWalkTime(from: userLoc, to: stopCoordinate) }
            .sheet(isPresented: $showNavigationSheet) {
                WalkingNavigationView(stopName: stopName, stopCoordinate: stopCoordinate,
                                     departureTime: departureTime, locationManager: locationManager)
            }
        }
    }
    
    @ViewBuilder
    private func badgeContent(userLocation: CLLocationCoordinate2D) -> some View {
        let time = walkTime ?? walkingService.estimateWalkTime(from: userLocation, to: stopCoordinate)
        let minutes = Int(ceil(time / 60))
        let isReachable = departureTime.map { 
            walkingService.isDepartureReachable(userLocation: userLocation, stop: stopCoordinate, departureTime: $0)
        } ?? true
        
        if compact {
            HStack(spacing: 4) {
                Image(systemName: "figure.walk").font(.system(size: 10, weight: .semibold))
                Text("\(minutes)'").font(.system(size: 11, weight: .semibold)).monospacedDigit()
            }
            .foregroundColor(isReachable ? .blue : .orange)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Capsule().fill((isReachable ? Color.blue : Color.orange).opacity(0.12)))
            .accessibilityLabel("\(minutes) Minuten Fußweg")
        } else {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk").font(.system(size: 14, weight: .medium))
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(minutes) min Fußweg").font(.system(size: 12, weight: .medium))
                    if !isReachable { Text("Knapp!").font(.system(size: 10, weight: .semibold)).foregroundColor(.orange) }
                }
                Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
            }
            .foregroundColor(isReachable ? .blue : .orange)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill((isReachable ? Color.blue : Color.orange).opacity(0.1)))
        }
    }
}

// MARK: - Walking Time Label

struct WalkingTimeLabel: View {
    let userLocation: CLLocationCoordinate2D?
    let stopCoordinate: CLLocationCoordinate2D
    
    var body: some View {
        if let userLoc = userLocation {
            let time = WalkingRouteService.shared.estimateWalkTime(from: userLoc, to: stopCoordinate)
            Label("\(Int(ceil(time / 60))) min", systemImage: "figure.walk")
                .font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - Reachability Indicator

struct ReachabilityIndicator: View {
    let urgencyLevel: UrgencyLevel
    
    enum UrgencyLevel {
        case comfortable, tight, critical, missed
        
        var color: Color {
            switch self {
            case .comfortable: return .green
            case .tight: return .orange
            case .critical: return .red
            case .missed: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .comfortable: return "checkmark.circle.fill"
            case .tight: return "exclamationmark.circle.fill"
            case .critical: return "exclamationmark.triangle.fill"
            case .missed: return "xmark.circle.fill"
            }
        }
        
        var label: String {
            switch self {
            case .comfortable: return "Erreichbar"
            case .tight: return "Knapp"
            case .critical: return "Eile!"
            case .missed: return "Verpasst"
            }
        }
        
        static func calculate(walkTimeSeconds: TimeInterval, departureTime: Date) -> UrgencyLevel {
            let buffer = departureTime.timeIntervalSinceNow - walkTimeSeconds
            if buffer < 0 { return .missed }
            if buffer < 120 { return .critical }
            if buffer < 300 { return .tight }
            return .comfortable
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: urgencyLevel.icon)
            Text(urgencyLevel.label)
        }
        .font(.caption.weight(.medium))
        .foregroundColor(urgencyLevel.color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(urgencyLevel.color.opacity(0.15)))
    }
}
