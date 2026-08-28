//
//  NetworkError.swift
//  Linio
//
//  Einheitliches Error-Handling für Netzwerk- und API-Fehler.
//

import Foundation

/// Einheitlicher Error-Typ für alle Netzwerk- und API-Operationen.
enum NetworkError: LocalizedError, Equatable {
    // Netzwerk-Fehler
    case noInternet
    case timeout
    case serverUnreachable
    
    // HTTP-Fehler
    case unauthorized      // 401
    case forbidden         // 403
    case notFound          // 404
    case serverError       // 500+
    case httpError(code: Int)
    
    // API-spezifische Fehler
    case invalidResponse
    case decodingFailed(reason: String)
    case graphQLError(message: String)
    case noData
    
    // Auth-Fehler
    case tokenExpired
    case authenticationFailed
    
    // Allgemein
    case unknown(message: String)
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch self {
        case .noInternet: return "Keine Internetverbindung"
        case .timeout: return "Zeitüberschreitung"
        case .serverUnreachable: return "Server nicht erreichbar"
        case .unauthorized: return "Nicht autorisiert"
        case .forbidden: return "Zugriff verweigert"
        case .notFound: return "Nicht gefunden"
        case .serverError: return "Serverfehler"
        case .httpError(let code): return "HTTP-Fehler \(code)"
        case .invalidResponse: return "Ungültige Antwort"
        case .decodingFailed(let reason): return "Decodierung: \(reason)"
        case .graphQLError(let message): return message
        case .noData: return "Keine Daten"
        case .tokenExpired: return "Sitzung abgelaufen"
        case .authenticationFailed: return "Anmeldung fehlgeschlagen"
        case .unknown(let message): return message
        }
    }
    
    /// Kurze Beschreibung für UI-Anzeige
    var shortDescription: String {
        switch self {
        case .noInternet: return "Keine Verbindung"
        case .timeout: return "Zeitüberschreitung"
        case .serverUnreachable: return "Server nicht erreichbar"
        case .unauthorized, .tokenExpired: return "Bitte neu anmelden"
        case .forbidden: return "Zugriff verweigert"
        case .notFound: return "Nicht gefunden"
        case .serverError: return "Serverfehler"
        case .httpError(let code): return "Fehler \(code)"
        case .invalidResponse, .decodingFailed: return "Ungültige Antwort"
        case .graphQLError: return "API-Fehler"
        case .noData: return "Keine Daten"
        case .authenticationFailed: return "Anmeldung fehlgeschlagen"
        case .unknown: return "Unbekannter Fehler"
        }
    }
    
    /// SF Symbol für UI-Anzeige
    var iconName: String {
        switch self {
        case .noInternet: return "wifi.slash"
        case .timeout: return "clock.badge.xmark"
        case .serverUnreachable, .serverError: return "server.rack"
        case .unauthorized, .forbidden, .tokenExpired, .authenticationFailed: return "lock.shield"
        case .notFound: return "questionmark.folder"
        default: return "exclamationmark.triangle"
        }
    }
    
    /// Ob der Fehler durch Retry behebbar sein könnte
    var isRetryable: Bool {
        switch self {
        case .noInternet, .timeout, .serverUnreachable, .serverError, .tokenExpired, .unauthorized:
            return true
        default:
            return false
        }
    }
}
