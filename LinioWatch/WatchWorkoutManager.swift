// WatchWorkoutManager.swift
// HealthKit Workout-Integration für den Fußweg zur Haltestelle

import Foundation
import HealthKit
import Combine

/// Manager für Workout-Tracking des Fußwegs zur Haltestelle
@MainActor
class WatchWorkoutManager: NSObject, ObservableObject {
    static let shared = WatchWorkoutManager()
    
    @Published var isWorkoutActive = false
    @Published var elapsedSeconds: Int = 0
    @Published var distanceMeters: Double = 0
    @Published var activeCalories: Double = 0
    @Published var heartRate: Double = 0
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startDate: Date?
    private var destinationStation: String?
    
    private override init() { super.init() }
    
    private let typesToShare: Set<HKSampleType> = [HKQuantityType.workoutType()]
    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]
    
    var isHealthKitAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    
    func requestAuthorization() async {
        guard isHealthKitAvailable else { errorMessage = "HealthKit nicht verfügbar"; return }
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            authorizationStatus = healthStore.authorizationStatus(for: HKQuantityType.workoutType())
        } catch {
            errorMessage = "Berechtigung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
    
    func startWalkToStation(_ stationName: String) async {
        guard isHealthKitAvailable else { errorMessage = "HealthKit nicht verfügbar"; return }
        if authorizationStatus == .notDetermined { await requestAuthorization() }
        guard authorizationStatus == .sharingAuthorized else { errorMessage = "Keine Berechtigung"; return }
        
        destinationStation = stationName
        startDate = Date()
        
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            
            let start = Date()
            workoutSession?.startActivity(with: start)
            try await workoutBuilder?.beginCollection(at: start)
            
            isWorkoutActive = true
            elapsedSeconds = 0
            distanceMeters = 0
            activeCalories = 0
            startTimer()
            WatchHapticManager.shared.playSuccess()
        } catch {
            errorMessage = "Workout Start fehlgeschlagen: \(error.localizedDescription)"
        }
    }
    
    func endWorkout() async {
        guard let session = workoutSession, let builder = workoutBuilder else { return }
        let endDate = Date()
        session.end()
        
        do {
            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
            isWorkoutActive = false
            stopTimer()
            WatchHapticManager.shared.playSuccess()
        } catch {
            errorMessage = "Workout Ende fehlgeschlagen: \(error.localizedDescription)"
        }
        workoutSession = nil
        workoutBuilder = nil
    }
    
    func pauseWorkout() { workoutSession?.pause(); stopTimer() }
    func resumeWorkout() { workoutSession?.resume(); startTimer() }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startDate else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }
    
    private func stopTimer() { timer?.invalidate(); timer = nil }
    
    private func updateStatistics(_ statistics: HKStatistics) {
        switch statistics.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            if let v = statistics.mostRecentQuantity()?.doubleValue(for: .count().unitDivided(by: .minute())) { heartRate = v }
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            if let v = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) { activeCalories = v }
        case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
            if let v = statistics.sumQuantity()?.doubleValue(for: .meter()) { distanceMeters = v }
        default: break
        }
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ s: HKWorkoutSession, didChangeTo to: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in self.isWorkoutActive = (to == .running || to == .paused) }
    }
    nonisolated func workoutSession(_ s: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.errorMessage = error.localizedDescription; self.isWorkoutActive = false }
    }
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ b: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        for type in types {
            guard let qt = type as? HKQuantityType, let stats = b.statistics(for: qt) else { continue }
            Task { @MainActor in self.updateStatistics(stats) }
        }
    }
    nonisolated func workoutBuilderDidCollectEvent(_ b: HKLiveWorkoutBuilder) {}
}
