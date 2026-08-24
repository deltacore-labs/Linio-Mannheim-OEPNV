// WatchHapticManager.swift
// Haptic Feedback für Umstieg und Ankunft auf der Apple Watch

import Foundation
import WatchKit
import Combine

/// Manager für haptisches Feedback während der Fahrt
@MainActor
class WatchHapticManager: ObservableObject {
    static let shared = WatchHapticManager()
    
    @Published var isMonitoringActive = false
    @Published var lastHapticEvent: HapticEvent?
    
    private var monitoringTimer: Timer?
    private var lastNotifiedLegIndex: Int = -1
    private var hasNotifiedArrival = false
    private var currentTripId: String?
    
    private let arrivalWarningThreshold: TimeInterval = 120
    private let interchangeWarningThreshold: TimeInterval = 60
    
    private init() {}
    
    enum HapticEvent: Equatable {
        case departureReminder(minutesUntil: Int)
        case interchangeSoon(nextLine: String, minutesUntil: Int)
        case interchangeNow(nextLine: String)
        case arrivalSoon(station: String, minutesUntil: Int)
        case arrived(station: String)
        
        var description: String {
            switch self {
            case .departureReminder(let mins): return "Abfahrt in \(mins) Min"
            case .interchangeSoon(let line, let mins): return "Umstieg auf \(line) in \(mins) Min"
            case .interchangeNow(let line): return "Jetzt umsteigen auf \(line)"
            case .arrivalSoon(let station, let mins): return "Ankunft \(station) in \(mins) Min"
            case .arrived(let station): return "Angekommen: \(station)"
            }
        }
    }
    
    func startMonitoring(for trip: WidgetTripData) {
        stopMonitoring()
        currentTripId = trip.id
        lastNotifiedLegIndex = -1
        hasNotifiedArrival = false
        isMonitoringActive = true
        checkAndNotify(trip: trip)
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkAndNotify(trip: trip) }
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoringActive = false
        currentTripId = nil
    }
    
    func playHaptic(_ type: WKHapticType) { WKInterfaceDevice.current().play(type) }
    func playSuccess() { playHaptic(.success) }
    func playNotification() { playHaptic(.notification) }
    
    func playWarning() {
        playHaptic(.directionUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.directionUp)
        }
    }
    
    private func checkAndNotify(trip: WidgetTripData) {
        let now = Date()
        
        if let arrivalDate = WatchDateHelper.parse(trip.endTime) {
            let timeToArrival = arrivalDate.timeIntervalSince(now)
            
            if timeToArrival <= 0 && !hasNotifiedArrival {
                hasNotifiedArrival = true
                triggerEvent(.arrived(station: trip.endStation))
                stopMonitoring()
                return
            } else if timeToArrival > 0 && timeToArrival <= arrivalWarningThreshold && !hasNotifiedArrival {
                let mins = max(1, Int(timeToArrival / 60))
                triggerEvent(.arrivalSoon(station: trip.endStation, minutesUntil: mins))
                hasNotifiedArrival = true
            }
        }
        
        let timedLegs = trip.legs.filter { $0.isTimedLeg }
        for (index, leg) in timedLegs.enumerated() {
            guard index > lastNotifiedLegIndex,
                  let legDep = leg.departureTime, let legArr = leg.arrivalTime,
                  let depDate = WatchDateHelper.parse(legDep),
                  let arrDate = WatchDateHelper.parse(legArr),
                  now >= depDate && now < arrDate else { continue }
            
            let timeToEnd = arrDate.timeIntervalSince(now)
            if index + 1 < timedLegs.count {
                let nextLine = WatchStyleHelper.shortName(timedLegs[index + 1].serviceName)
                if timeToEnd <= interchangeWarningThreshold {
                    lastNotifiedLegIndex = index
                    triggerEvent(.interchangeNow(nextLine: nextLine))
                } else if timeToEnd <= arrivalWarningThreshold {
                    lastNotifiedLegIndex = index
                    triggerEvent(.interchangeSoon(nextLine: nextLine, minutesUntil: max(1, Int(timeToEnd / 60))))
                }
            }
        }
    }
    
    private func triggerEvent(_ event: HapticEvent) {
        lastHapticEvent = event
        switch event {
        case .departureReminder, .interchangeSoon, .arrivalSoon: playNotification()
        case .interchangeNow: playWarning()
        case .arrived:
            playSuccess()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { WKInterfaceDevice.current().play(.success) }
        }
    }
}

extension WatchHapticManager {
    func startMonitoring(for trip: TripData) {
        let widgetTrip = WidgetTripData(
            id: trip.id, startTime: trip.startTime, endTime: trip.endTime,
            interchanges: trip.interchanges, startStation: trip.startStation, endStation: trip.endStation,
            legs: trip.legs.map {
                WidgetTripLegData(legType: $0.legType, boardStopName: $0.boardStopName, alightStopName: $0.alightStopName,
                    departureTime: $0.departureTime, arrivalTime: $0.arrivalTime, serviceName: $0.serviceName,
                    serviceType: $0.serviceType, destinationLabel: $0.destinationLabel)
            }
        )
        startMonitoring(for: widgetTrip)
    }
}
