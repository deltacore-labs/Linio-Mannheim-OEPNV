//  AuthService.swift
//  Linio
//

import Foundation
import Combine
import Security

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    nonisolated init() {}

    @Published var accessToken: String?
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    @Published var authError: String?

    private var tokenExpiryDate: Date?
    
    /// Laufende Authentifizierungs-Task – verhindert parallele Token-Requests
    private var activeAuthTask: Task<Void, Never>?

    // MARK: - Konfiguration (verschlüsselt)

    private var configManager = SecureConfigurationManager.shared

    private var clientID: String? {
        guard let id = configManager.clientID,
              !id.isEmpty, !id.hasPrefix("$(") else { return nil }
        return id
    }

    private var clientSecret: String? {
        guard let secret = configManager.clientSecret,
              !secret.isEmpty, !secret.hasPrefix("$(") else { return nil }
        return secret
    }

    private var tenantID: String? {
        guard let tenant = configManager.tenantID,
              !tenant.isEmpty, !tenant.hasPrefix("$(") else { return nil }
        return tenant
    }

    private var resource: String? {
        guard let res = configManager.resource,
              !res.isEmpty, !res.hasPrefix("$(") else { return nil }
        return res
    }

    // MARK: - Token Gültigkeit

    var isTokenValid: Bool {
        guard isAuthenticated, accessToken != nil else { return false }
        guard let expiry = tokenExpiryDate else { return false }
        // Token als ungültig betrachten 60 Sekunden vor Ablauf
        return Date() < expiry.addingTimeInterval(-60)
    }
    
    /// Stellt sicher, dass ein gültiger Token vorhanden ist und gibt ihn zurück.
    /// Führt bei Bedarf automatisch eine Authentifizierung durch.
    func ensureValidToken() async -> String? {
        if !isTokenValid { await autoAuthenticate() }
        return accessToken
    }

    // MARK: - Auto Login

    func autoAuthenticate() async {
        if isTokenValid {
            DebugLog.auth("ℹ️ Token noch gültig, kein erneuter Login nötig")
            return
        }
        if isAuthenticated && !isTokenValid {
            DebugLog.auth("🔄 Token abgelaufen, erneuere...")
        }
        await authenticate()
    }

    // MARK: - Authentication

    func authenticate() async {
        // Wenn bereits eine Authentifizierung läuft, auf deren Ergebnis warten
        if let existingTask = activeAuthTask {
            await existingTask.value
            return
        }

        isAuthenticating = true
        authError = nil
        
        let task = Task { @MainActor [weak self] in
            await self?.performAuthentication()
            return
        }
        activeAuthTask = task
        await task.value
        activeAuthTask = nil
    }
    
    private func performAuthentication() async {

        // Konfiguration prüfen
        guard let id = clientID else {
            setError("RNV_CLIENT_ID ist nicht konfiguriert oder konnte nicht entschlüsselt werden.")
            return
        }
        guard let secret = clientSecret else {
            setError("RNV_CLIENT_SECRET ist nicht konfiguriert oder konnte nicht entschlüsselt werden.")
            return
        }
        guard let tenant = tenantID else {
            setError("RNV_TENANT_ID ist nicht konfiguriert oder konnte nicht entschlüsselt werden.")
            return
        }
        guard let res = resource else {
            setError("RNV_RESOURCE ist nicht konfiguriert oder konnte nicht entschlüsselt werden.")
            return
        }

        let urlString = "https://login.microsoftonline.com/\(tenant)/oauth2/token"

        guard let url = URL(string: urlString) else {
            setError("Ungültige Auth-URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: id),
            URLQueryItem(name: "client_secret", value: secret),
            URLQueryItem(name: "resource", value: res),
        ]
        guard let bodyString = bodyComponents.percentEncodedQuery else {
            setError("Fehler beim Kodieren der Credentials.")
            return
        }
        request.httpBody = bodyString.data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                setError("Auth-Server antwortete mit Status \(httpResponse.statusCode).")
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let token = json["access_token"] as? String {
                    // Token-Ablaufzeit berechnen (Standard: 3600 Sekunden)
                    let expiresIn = json["expires_in"] as? TimeInterval ?? 3600
                    let expiry = Date().addingTimeInterval(expiresIn)

                    self.accessToken = token
                    self.tokenExpiryDate = expiry
                    self.isAuthenticated = true
                    self.isAuthenticating = false
                    self.authError = nil

                    // Token in Shared Keychain speichern (zugänglich für Widget-Extension)
                    if let tokenData = token.data(using: .utf8) {
                        var keychainQuery = keychainBaseQuery
                        keychainQuery[kSecValueData as String] = tokenData
                        keychainQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                        SecItemDelete(keychainQuery as CFDictionary)
                        SecItemAdd(keychainQuery as CFDictionary, nil)
                    }
                    // Ablaufzeit und URL weiterhin in App Group (nicht sicherheitskritisch)
                    let appGroupDefaults = UserDefaults(suiteName: AppConfiguration.appGroupID)
                    appGroupDefaults?.set(expiry.timeIntervalSince1970, forKey: AppConfiguration.UserDefaultsKey.widgetAccessTokenExpiry.rawValue)
                    let rawGraphQLURL = Bundle.main.object(forInfoDictionaryKey: "RNV_GRAPHQL_URL") as? String
                    let graphqlURL: String
                    if let raw = rawGraphQLURL, !raw.isEmpty, !raw.contains("$(") {
                        graphqlURL = raw
                    } else {
                        graphqlURL = AppConfiguration.fallbackGraphQLURL
                    }
                    appGroupDefaults?.set(graphqlURL, forKey: AppConfiguration.UserDefaultsKey.widgetGraphQLURL.rawValue)

                    PhoneConnectivityManager.shared.pushCredentialsToWatch(token: token, tokenExpiry: expiry)
                    DebugLog.auth("✅ Anmeldung erfolgreich. Token läuft ab um: \(expiry)")
                } else if let errorDesc = json["error_description"] as? String {
                    setError("Auth-Fehler: \(errorDesc)")
                } else {
                    setError("Unbekannte Auth-Antwort vom Server.")
                }
            } else {
                // JSON konnte nicht als Dictionary geparst werden (z.B. leere oder unerwartete Antwort)
                setError("Ungültiges Antwortformat vom Auth-Server.")
            }
        } catch {
            setError("Netzwerkfehler: \(error.localizedDescription)")
        }
    }

    // MARK: - Hilfsfunktionen

    private var keychainBaseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AppConfiguration.widgetKeychainService,
            kSecAttrAccount as String: AppConfiguration.widgetKeychainTokenKey,
            kSecAttrAccessGroup as String: AppConfiguration.widgetKeychainAccessGroup
        ]
    }

    private func setError(_ message: String) {
        DebugLog.auth("❌ \(message)")
        self.authError = message
        self.isAuthenticating = false
        self.isAuthenticated = false
        self.accessToken = nil
        self.tokenExpiryDate = nil
    }

    func logout() {
        accessToken = nil
        tokenExpiryDate = nil
        isAuthenticated = false
        authError = nil

        // Token aus Keychain löschen
        SecItemDelete(keychainBaseQuery as CFDictionary)
        // Ablaufzeit und URL aus App Group löschen
        let appGroupDefaults = UserDefaults(suiteName: AppConfiguration.appGroupID)
        appGroupDefaults?.removeObject(forKey: AppConfiguration.UserDefaultsKey.widgetAccessTokenExpiry.rawValue)
        appGroupDefaults?.removeObject(forKey: AppConfiguration.UserDefaultsKey.widgetGraphQLURL.rawValue)

        DebugLog.auth("🔓 Abgemeldet")
    }
}
