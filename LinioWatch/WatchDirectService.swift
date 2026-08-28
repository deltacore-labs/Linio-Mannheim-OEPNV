// Ermöglicht der Watch selbständige API-Anfragen wenn das iPhone nicht erreichbar ist.
// Credentials werden vom iPhone via ApplicationContext übertragen und lokal gecacht.

import Foundation
import Security

class WatchDirectService {
    static let shared = WatchDirectService()

    private static let hubStationNames = ["Mannheim Hauptbahnhof", "Heidelberg Hauptbahnhof", "Paradeplatz"]
    private var cachedHubIDs: [String]? = nil
    private let credentialsKey = "watchCachedCredentials"
    private let keychainService = "com.stefanfriedrich.rnvapp.watch"

    struct Credentials: Codable {
        let clientID: String
        let tenantID: String
        let resource: String
        let graphQLURL: String
        var accessToken: String?
        var tokenExpiry: TimeInterval?
    }

    private init() {
        // Einmalige Migration aus UserDefaults → Keychain beim ersten Start
        if keychainLoad() == nil,
           let data = UserDefaults.standard.data(forKey: credentialsKey),
           (try? JSONDecoder().decode(Credentials.self, from: data)) != nil {
            keychainSave(data)
            UserDefaults.standard.removeObject(forKey: credentialsKey)
        }
    }

    // MARK: - Keychain helpers

    private func keychainSave(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: credentialsKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func keychainLoad() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: credentialsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return data
    }

    // MARK: - Credentials

    func saveCredentials(_ creds: Credentials) {
        guard let data = try? JSONEncoder().encode(creds) else { return }
        keychainSave(data)
        UserDefaults.standard.removeObject(forKey: credentialsKey)
    }

    func updateToken(_ token: String, expiry: TimeInterval) {
        guard var creds = loadCredentials() else { return }
        creds.accessToken = token
        creds.tokenExpiry = expiry
        saveCredentials(creds)
    }

    func loadCredentials() -> Credentials? {
        guard let data = keychainLoad() else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    var hasCredentials: Bool { loadCredentials() != nil }

    // MARK: - Token

    func getValidToken() async -> String? {
        guard var creds = loadCredentials() else { return nil }

        if let token = creds.accessToken,
           let expiry = creds.tokenExpiry,
           Date().timeIntervalSince1970 < expiry - 60 {
            return token
        }

        guard let token = await Self.authenticate(creds: creds) else { return nil }

        creds.accessToken = token
        creds.tokenExpiry = Date().timeIntervalSince1970 + 3600
        saveCredentials(creds)
        return token
    }

    // MARK: - Departures

    func fetchDepartures(stationID: String) async -> [WatchDeparture]? {
        guard let creds = loadCredentials(),
              let token = await getValidToken()
        else { return nil }

        if cachedHubIDs == nil {
            let ids = await withTaskGroup(of: String?.self) { group in
                for name in Self.hubStationNames {
                    group.addTask {
                        await Self.resolveStationID(name: name, token: token, graphQLURL: creds.graphQLURL)
                    }
                }
                var result: [String] = []
                for await id in group {
                    if let id { result.append(id) }
                }
                return result
            }
            cachedHubIDs = ids
        }

        guard let hubIDs = cachedHubIDs, !hubIDs.isEmpty else { return nil }

        let time = ISO8601DateFormatter().string(from: Date())
        let allDepartures = await withTaskGroup(of: [WatchDeparture].self) { group in
            for hubID in hubIDs.prefix(3) where hubID != stationID {
                group.addTask {
                    await Self.fetchLegs(from: stationID, to: hubID, time: time, token: token, graphQLURL: creds.graphQLURL)
                }
            }
            var result: [WatchDeparture] = []
            for await deps in group {
                result.append(contentsOf: deps)
            }
            return result
        }

        var seen = Set<String>()
        var result = allDepartures.filter { seen.insert("\($0.lineName)-\($0.scheduledTime)").inserted }
        result.sort {
            let a = WatchDateHelper.parse($0.scheduledTime) ?? .distantFuture
            let b = WatchDateHelper.parse($1.scheduledTime) ?? .distantFuture
            return a < b
        }
        return result
    }

    // MARK: - Netzwerk (static – kein self-Capture in TaskGroup nötig)

    private static func authenticate(creds: Credentials) async -> String? {
        // Watch kann ohne clientSecret nicht selbst authentifizieren.
        // accessToken muss vom iPhone per WatchConnectivity kommen.
        return nil
    }

    private static func resolveStationID(name: String, token: String, graphQLURL: String) async -> String? {
        let safe  = name.replacingOccurrences(of: "\"", with: "")
        let query = "{ stations(first: 1, name: \"\(safe)\") { elements { ... on Station { globalID } } } }"
        guard let data     = try? await execute(query: query, token: token, graphQLURL: graphQLURL),
              let json     = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let d        = json["data"]       as? [String: Any],
              let s        = d["stations"]      as? [String: Any],
              let elements = s["elements"]      as? [[String: Any]],
              let globalID = elements.first?["globalID"] as? String
        else { return nil }
        return globalID
    }

    private static func fetchLegs(from originID: String, to destID: String,
                                   time: String, token: String, graphQLURL: String) async -> [WatchDeparture] {
        let query = """
        {
          trips(
            originGlobalID: "\(originID)"
            destinationGlobalID: "\(destID)"
            departureTime: "\(time)"
          ) {
            legs {
              ... on TimedLeg {
                board {
                  timetabledTime { isoString }
                  estimatedTime  { isoString }
                }
                service { name type destinationLabel }
              }
            }
          }
        }
        """

        guard let data  = try? await execute(query: query, token: token, graphQLURL: graphQLURL),
              let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let d     = json["data"]  as? [String: Any],
              let trips = d["trips"]    as? [[String: Any]]
        else { return [] }

        return trips.compactMap { trip -> WatchDeparture? in
            guard let legs      = trip["legs"]    as? [[String: Any]],
                  let firstLeg  = legs.first(where: { $0["board"] != nil }),
                  let board     = firstLeg["board"]   as? [String: Any],
                  let service   = firstLeg["service"] as? [String: Any],
                  let lineName  = service["name"]     as? String,
                  let direction = service["destinationLabel"] as? String,
                  let timetabled = (board["timetabledTime"] as? [String: Any])?["isoString"] as? String,
                  timetabled != "null", !timetabled.isEmpty
            else { return nil }

            let estimated   = (board["estimatedTime"] as? [String: Any])?["isoString"] as? String
            let serviceType = service["type"] as? String

            let delayMinutes: Int? = {
                guard let s = WatchDateHelper.parse(timetabled),
                      let e = estimated.flatMap({ WatchDateHelper.parse($0) }) else { return nil }
                return max(0, Int(e.timeIntervalSince(s) / 60))
            }()

            return WatchDeparture(
                id: "\(lineName)-\(timetabled)",
                lineName: lineName,
                direction: direction,
                scheduledTime: timetabled,
                estimatedTime: estimated,
                serviceType: serviceType,
                delayMinutes: delayMinutes
            )
        }
    }

    private static func execute(query: String, token: String, graphQLURL: String) async throws -> Data {
        guard let url = URL(string: graphQLURL) else { throw URLError(.badURL) }
        let body = try JSONSerialization.data(withJSONObject: ["query": query])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        request.timeoutInterval = 8
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
