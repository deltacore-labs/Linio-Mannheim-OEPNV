//
//  WalletDebugLogger.swift
//  Linio
//
//  TestFlight-fähiger Debug-Logger für Wallet-Probleme.
//  Funktioniert in DEBUG UND RELEASE Builds!
//

import Foundation
import os.log
import UIKit
import PassKit

/// Ein Logger speziell für Wallet-Debugging, der auch in TestFlight funktioniert
final class WalletDebugLogger {
    static let shared = WalletDebugLogger()
    
    private let logger = Logger(subsystem: "com.stefanfriedrich.rnvapp", category: "Wallet")
    private let queue = DispatchQueue(label: "com.stefanfriedrich.walletdebug", qos: .utility)
    private var logs: [LogEntry] = []
    private let maxEntries = 500
    
    private let logFileURL: URL? = {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.stefanfriedrich.rnvapp")?
            .appendingPathComponent("wallet_debug.log")
    }()
    
    struct LogEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let level: LogLevel
        let message: String
        let details: String?
        
        enum LogLevel: String, Codable {
            case info = "ℹ️"
            case success = "✅"
            case warning = "⚠️"
            case error = "❌"
            case debug = "🔍"
        }
        
        var formattedString: String {
            let df = DateFormatter()
            df.dateFormat = "HH:mm:ss.SSS"
            let time = df.string(from: timestamp)
            var str = "[\(time)] \(level.rawValue) \(message)"
            if let details = details { str += "\n    → \(details)" }
            return str
        }
    }
    
    private init() {
        loadLogsFromDisk()
        logSystemInfo()
    }
    
    // MARK: - Public API
    
    func info(_ message: String, details: String? = nil) { log(.info, message: message, details: details) }
    func success(_ message: String, details: String? = nil) { log(.success, message: message, details: details) }
    func warning(_ message: String, details: String? = nil) { log(.warning, message: message, details: details) }
    func error(_ message: String, details: String? = nil) { log(.error, message: message, details: details) }
    func debug(_ message: String, details: String? = nil) { log(.debug, message: message, details: details) }
    
    func logError(_ error: Error, context: String) {
        let nsError = error as NSError
        let details = "Domain: \(nsError.domain), Code: \(nsError.code), Desc: \(error.localizedDescription)"
        log(.error, message: context, details: details)
    }
    
    func getAllLogs() -> [LogEntry] { queue.sync { logs } }
    
    func getLogsAsText() -> String {
        let entries = getAllLogs()
        let header = """
            ═══════════════════════════════════════════════════
            🎫 LINIO WALLET DEBUG LOG
            App: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))
            iOS: \(UIDevice.current.systemVersion) | Device: \(UIDevice.current.model)
            Generated: \(Date())
            ═══════════════════════════════════════════════════
            
            """
        return header + entries.map { $0.formattedString }.joined(separator: "\n")
    }
    
    func clearLogs() {
        queue.async { [weak self] in
            self?.logs = []
            self?.saveToDisk()
        }
        logSystemInfo()
    }
    
    // MARK: - Private
    
    private func log(_ level: LogEntry.LogLevel, message: String, details: String?) {
        let entry = LogEntry(id: UUID(), timestamp: Date(), level: level, message: message, details: details)
        logger.info("[\(level.rawValue, privacy: .public)] \(message, privacy: .public) | \(details ?? "", privacy: .public)")
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(entry)
            if self.logs.count > self.maxEntries { self.logs.removeFirst(self.logs.count - self.maxEntries) }
            self.saveToDisk()
        }
    }
    
    private func logSystemInfo() {
        info("Logger gestartet", details: "TestFlight Debug Mode")
        
        let canAddPasses = PKAddPassesViewController.canAddPasses()
        info("Wallet-Status", details: "canAddPasses: \(canAddPasses)")
        
        let certName = Bundle.main.object(forInfoDictionaryKey: "WalletCertName") as? String ?? "nicht gesetzt"
        let passTypeID = Bundle.main.object(forInfoDictionaryKey: "WalletPassTypeID") as? String ?? "nicht gesetzt"
        debug("Wallet-Config", details: "Cert: \(certName), PassTypeID: \(passTypeID.prefix(25))...")
        
        if Bundle.main.path(forResource: certName, ofType: "p12") != nil {
            success("Zertifikat gefunden", details: "\(certName).p12")
        } else {
            error("Zertifikat NICHT gefunden", details: "\(certName).p12 fehlt!")
        }
        
        if Bundle.main.path(forResource: "AppleWWDRCAG4", ofType: "cer") != nil {
            success("WWDR-Zertifikat OK")
        } else {
            error("WWDR-Zertifikat fehlt!")
        }
    }
    
    private func saveToDisk() {
        guard let url = logFileURL, let data = try? JSONEncoder().encode(logs) else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    private func loadLogsFromDisk() {
        guard let url = logFileURL,
              let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([LogEntry].self, from: data) else { return }
        logs = saved
    }
    
    // MARK: - Convenience für WalletPassGenerator
    
    func logCertImport(status: OSStatus) {
        if status == errSecSuccess {
            success("Zertifikat importiert")
        } else {
            error("Zertifikat-Import fehlgeschlagen", details: "OSStatus: \(status)")
        }
    }
    
    func logPassCreation(success: Bool, size: Int? = nil) {
        if success {
            self.success("PKPass erstellt", details: size.map { "\($0) bytes" })
        } else {
            error("PKPass-Erstellung fehlgeschlagen")
        }
    }
}
