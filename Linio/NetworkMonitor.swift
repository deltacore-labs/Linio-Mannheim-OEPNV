//
//  NetworkMonitor.swift
//  Linio
//
//  Performance-optimiert: Monitor kann bei Bedarf gestartet/gestoppt werden
//  und stoppt automatisch im Hintergrund.
//

import Network
import Combine
import Foundation
import UIKit

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isMonitoring = false
    private var observerTokens: [Any] = []
    
    /// Zählt aktive Subscriber – Monitor läuft nur wenn > 0
    private var activeSubscriberCount = 0

    enum ConnectionType {
        case wifi, cellular, wiredEthernet, unknown
    }

    private init() {
        setupLifecycleObservers()
        startMonitoring()
    }
    
    deinit {
        for token in observerTokens {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // MARK: - Lifecycle Management
    
    private func setupLifecycleObservers() {
        let bgToken = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopMonitoring()
        }
        
        let fgToken = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startMonitoring()
        }
        
        observerTokens = [bgToken, fgToken]
    }
    
    // MARK: - Public API
    
    /// Registriert einen aktiven Subscriber (z.B. eine View die den Status braucht)
    func registerSubscriber() {
        activeSubscriberCount += 1
        if activeSubscriberCount == 1 {
            startMonitoring()
        }
    }
    
    /// Entfernt einen Subscriber
    func unregisterSubscriber() {
        activeSubscriberCount = max(0, activeSubscriberCount - 1)
        // Monitor läuft weiter für schnellen Reconnect-Check
    }
    
    // MARK: - Internal Monitoring
    
    private func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor?.start(queue: queue)
        isMonitoring = true
        
        #if DEBUG
        print("🌐 [NETWORK] Monitor gestartet")
        #endif
    }
    
    private func stopMonitoring() {
        guard isMonitoring else { return }
        
        monitor?.cancel()
        monitor = nil
        isMonitoring = false
        
        #if DEBUG
        print("🌐 [NETWORK] Monitor gestoppt (Hintergrund)")
        #endif
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .unknown
    }
}
