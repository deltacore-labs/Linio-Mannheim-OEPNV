//
//  SecureConfigurationManager.swift
//  Linio
//
//  Verwaltet verschlüsselte Konfigurationswerte
//

import Foundation

/// Verwaltet verschlüsselte App-Secrets
/// Secrets sind in EncryptedSecrets.json verschlüsselt gespeichert
class SecureConfigurationManager {
    
    static let shared = SecureConfigurationManager()
    
    private var decryptedSecrets: [String: String] = [:]
    private let encryptionService = EncryptionService.shared
    
    private init() {
        loadAndDecryptSecrets()
    }
    
    // MARK: - Public Accessors (RNV)
    
    var clientID: String? {
        decryptedSecrets["RNV_CLIENT_ID"]
    }
    
    var clientSecret: String? {
        decryptedSecrets["RNV_CLIENT_SECRET"]
    }
    
    var tenantID: String? {
        decryptedSecrets["RNV_TENANT_ID"]
    }
    
    var resource: String? {
        decryptedSecrets["RNV_RESOURCE"]
    }
    
    var graphQLURL: String? {
        decryptedSecrets["RNV_GRAPHQL_URL"]
    }
    
    var signingKey: String? {
        decryptedSecrets["RNV_SIGNING_KEY"]
    }
    
    // MARK: - Public Accessors (Wallet)
    // Gibt nil zurück wenn der Wert leer ist, damit Fallbacks greifen können
    
    var walletPassTypeID: String? {
        nonEmptyValue(decryptedSecrets["WALLET_PASS_TYPE_ID"])
    }
    
    var walletTeamID: String? {
        nonEmptyValue(decryptedSecrets["WALLET_TEAM_ID"])
    }
    
    var walletCertName: String? {
        nonEmptyValue(decryptedSecrets["WALLET_CERT_NAME"])
    }
    
    var walletCertPassword: String? {
        // Password kann leer sein, daher keine nonEmpty-Prüfung
        decryptedSecrets["WALLET_CERT_PASSWORD"]
    }
    
    var walletAuthToken: String? {
        nonEmptyValue(decryptedSecrets["WALLET_AUTH_TOKEN"])
    }
    
    // Helper: Gibt nil zurück wenn String leer ist
    private func nonEmptyValue(_ value: String?) -> String? {
        guard let v = value, !v.isEmpty else { return nil }
        return v
    }
    
    // MARK: - Loading & Decryption
    
    private func loadAndDecryptSecrets() {
        // 1. Versuche verschlüsselte Datei zu laden
        guard let encryptedData = loadEncryptedSecretsFile() else {
            #if DEBUG
            print("ℹ️ [SecureConfig] Keine verschlüsselte Secrets-Datei gefunden - verwende Info.plist")
            #endif
            loadFallbackFromInfoPlist()
            return
        }
        
        // 2. Prüfe ob echte verschlüsselte Daten vorhanden sind (nicht Platzhalter)
        let hasValidEncryptedData = encryptedData.values.allSatisfy { value in
            // Platzhalter oder leere Werte erkennen
            !value.isEmpty && 
            !value.contains("...") && 
            !value.hasPrefix("AES-verschlüsselter") &&
            Data(base64Encoded: value) != nil
        }
        
        guard hasValidEncryptedData else {
            #if DEBUG
            print("ℹ️ [SecureConfig] EncryptedSecrets.json enthält Platzhalter - verwende Info.plist")
            #endif
            loadFallbackFromInfoPlist()
            return
        }
        
        // 3. Entschlüssele
        do {
            let decrypted = try encryptionService.decryptDictionary(encryptedData)
            self.decryptedSecrets = decrypted
            #if DEBUG
            print("✅ [SecureConfig] \(decrypted.count) Secrets erfolgreich entschlüsselt")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [SecureConfig] Entschlüsselung fehlgeschlagen: \(error.localizedDescription) - verwende Info.plist")
            #endif
            loadFallbackFromInfoPlist()
        }
    }
    
    /// Lädt verschlüsselte Secrets aus EncryptedSecrets.json
    private func loadEncryptedSecretsFile() -> [String: String]? {
        guard let url = Bundle.main.url(forResource: "EncryptedSecrets", withExtension: "json") else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }
        
        return json
    }
    
    /// Fallback: Lädt Secrets aus Info.plist (für Entwicklung)
    private func loadFallbackFromInfoPlist() {
        #if DEBUG
        print("✅ [SecureConfig] Verwende Werte aus Info.plist/xcconfig (Debug-Modus)")
        #endif
        
        decryptedSecrets = [
            // RNV Secrets
            "RNV_CLIENT_ID": Bundle.main.object(forInfoDictionaryKey: "RNV_CLIENT_ID") as? String ?? "",
            "RNV_CLIENT_SECRET": Bundle.main.object(forInfoDictionaryKey: "RNV_CLIENT_SECRET") as? String ?? "",
            "RNV_TENANT_ID": Bundle.main.object(forInfoDictionaryKey: "RNV_TENANT_ID") as? String ?? "",
            "RNV_RESOURCE": Bundle.main.object(forInfoDictionaryKey: "RNV_RESOURCE") as? String ?? "",
            "RNV_GRAPHQL_URL": Bundle.main.object(forInfoDictionaryKey: "RNV_GRAPHQL_URL") as? String ?? "",
            "RNV_SIGNING_KEY": Bundle.main.object(forInfoDictionaryKey: "RNV_SIGNING_KEY") as? String ?? "",
            // Wallet Secrets
            "WALLET_PASS_TYPE_ID": Bundle.main.object(forInfoDictionaryKey: "WalletPassTypeID") as? String ?? "",
            "WALLET_TEAM_ID": Bundle.main.object(forInfoDictionaryKey: "WalletTeamID") as? String ?? "",
            "WALLET_CERT_NAME": Bundle.main.object(forInfoDictionaryKey: "WalletCertName") as? String ?? "",
            "WALLET_CERT_PASSWORD": Bundle.main.object(forInfoDictionaryKey: "WalletCertPassword") as? String ?? "",
            "WALLET_AUTH_TOKEN": Bundle.main.object(forInfoDictionaryKey: "WalletAuthToken") as? String ?? ""
        ]
    }
    
    // MARK: - Encryption Helper (für Entwickler)
    
    /// Hilfsfunktion: Verschlüsselt die aktuellen Secrets aus Info.plist
    /// Nur für Setup - nicht in Production verwenden!
    func generateEncryptedSecretsFile() throws -> String {
        let secrets = [
            // RNV Secrets
            "RNV_CLIENT_ID": Bundle.main.object(forInfoDictionaryKey: "RNV_CLIENT_ID") as? String ?? "",
            "RNV_CLIENT_SECRET": Bundle.main.object(forInfoDictionaryKey: "RNV_CLIENT_SECRET") as? String ?? "",
            "RNV_TENANT_ID": Bundle.main.object(forInfoDictionaryKey: "RNV_TENANT_ID") as? String ?? "",
            "RNV_RESOURCE": Bundle.main.object(forInfoDictionaryKey: "RNV_RESOURCE") as? String ?? "",
            "RNV_GRAPHQL_URL": Bundle.main.object(forInfoDictionaryKey: "RNV_GRAPHQL_URL") as? String ?? "",
            "RNV_SIGNING_KEY": Bundle.main.object(forInfoDictionaryKey: "RNV_SIGNING_KEY") as? String ?? "",
            // Wallet Secrets
            "WALLET_PASS_TYPE_ID": Bundle.main.object(forInfoDictionaryKey: "WalletPassTypeID") as? String ?? "",
            "WALLET_TEAM_ID": Bundle.main.object(forInfoDictionaryKey: "WalletTeamID") as? String ?? "",
            "WALLET_CERT_NAME": Bundle.main.object(forInfoDictionaryKey: "WalletCertName") as? String ?? "",
            "WALLET_CERT_PASSWORD": Bundle.main.object(forInfoDictionaryKey: "WalletCertPassword") as? String ?? "",
            "WALLET_AUTH_TOKEN": Bundle.main.object(forInfoDictionaryKey: "WalletAuthToken") as? String ?? ""
        ]
        
        let encrypted = try encryptionService.encryptDictionary(secrets)
        let jsonData = try JSONEncoder().encode(encrypted)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw EncryptionError.encodingFailed
        }
        
        return jsonString
    }
}

extension EncryptionError {
    static let encodingFailed = EncryptionError.decodingFailed
}
