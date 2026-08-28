//
//  GraphQLService+Stations.swift
//  Linio
//

import Foundation

extension GraphQLService {

    // MARK: - Station Search (Location-Based)

    func searchStations(lat: Double, lon: Double, accessToken: String) async {
        isLoading = true
        lastError = nil

        let query = """
        {
          stations(first: 10, lat: \(lat), long: \(lon), distance: 2.0) {
            elements {
              ... on Station {
                hafasID
                globalID
                longName
                location {
                  lat
                  long
                }
              }
            }
          }
        }
        """

        do {
            let data = try await executeQuery(query: query, accessToken: accessToken)

            if let gqlError = extractGraphQLErrors(from: data) {
                lastError = gqlError
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["data"] as? [String: Any],
               let stations = responseData["stations"] as? [String: Any],
               let elements = stations["elements"] as? [[String: Any]] {

                self.stations = elements.compactMap { element -> Station? in
                    guard let hafasID = element["hafasID"] as? String,
                          let globalID = element["globalID"] as? String,
                          let longName = element["longName"] as? String else { return nil }
                    let locationObj = element["location"] as? [String: Any]
                    let lat = locationObj?["lat"] as? Double
                    let lon = locationObj?["long"] as? Double
                    return Station(hafasID: hafasID, globalID: globalID, longName: longName, latitude: lat, longitude: lon)
                }
            }
        } catch {
            lastError = NetworkError.from(error)
        }

        isLoading = false
    }

    // MARK: - Station Search (Name-Based)

    func searchStationsByName(name: String, accessToken: String) async {
        isLoading = true
        lastError = nil

        let safeName = sanitize(name)

        let query = """
        {
          stations(first: 20, name: "\(safeName)") {
            elements {
              ... on Station {
                hafasID
                globalID
                longName
                location {
                  lat
                  long
                }
              }
            }
          }
        }
        """

        do {
            let data = try await executeQuery(query: query, accessToken: accessToken)

            if let gqlError = extractGraphQLErrors(from: data) {
                lastError = gqlError
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["data"] as? [String: Any],
               let stations = responseData["stations"] as? [String: Any],
               let elements = stations["elements"] as? [[String: Any]] {

                self.stations = elements.compactMap { element -> Station? in
                    guard let hafasID = element["hafasID"] as? String,
                          let globalID = element["globalID"] as? String,
                          let longName = element["longName"] as? String else { return nil }
                    let locationObj = element["location"] as? [String: Any]
                    let lat = locationObj?["lat"] as? Double
                    let lon = locationObj?["long"] as? Double
                    return Station(hafasID: hafasID, globalID: globalID, longName: longName, latitude: lat, longitude: lon)
                }
            }
        } catch {
            lastError = NetworkError.from(error)
        }

        isLoading = false
    }

    // MARK: - Station Resolve (by name + globalID)

    /// Sucht eine Station anhand des Namens und gibt die zurück deren globalID übereinstimmt.
    /// Wird vom Watch-Pfad genutzt um die hafasID für die Journeys-API zu ermitteln.
    func resolveStation(globalID: String, name: String, accessToken: String) async -> Station? {
        let safeName = sanitize(name)
        let query = """
        {
          stations(first: 10, name: "\(safeName)") {
            elements {
              ... on Station {
                hafasID
                globalID
                longName
              }
            }
          }
        }
        """
        guard let data = try? await executeQuery(query: query, accessToken: accessToken) else {
            plog("resolveStation: executeQuery fehlgeschlagen für '\(name)'")
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let stationsObj = responseData["stations"] as? [String: Any],
              let elements = stationsObj["elements"] as? [[String: Any]] else {
            let snippet = String(data: data.prefix(300), encoding: .utf8) ?? "?"
            plog("resolveStation: unerwartete JSON-Struktur – \(snippet)")
            return nil
        }

        let foundIDs = elements.compactMap { $0["globalID"] as? String }
        plog("resolveStation: \(elements.count) Stationen, IDs: \(foundIDs.joined(separator: ","))")

        // Exakter Match zuerst
        for element in elements {
            guard let hafasID = element["hafasID"] as? String,
                  let gID = element["globalID"] as? String,
                  let longName = element["longName"] as? String,
                  gID == globalID else { continue }
            plog("resolveStation: exakter Match – hafasID=\(hafasID)")
            return Station(hafasID: hafasID, globalID: gID, longName: longName, latitude: nil, longitude: nil)
        }

        // Fallback: erstes Ergebnis nutzen (hafasID übernehmen, Watch-globalID behalten)
        if let first = elements.first,
           let hafasID = first["hafasID"] as? String,
           !hafasID.isEmpty {
            plog("resolveStation: kein exakter Match für '\(globalID)', nutze erstes Ergebnis hafasID=\(hafasID)")
            return Station(hafasID: hafasID, globalID: globalID, longName: name, latitude: nil, longitude: nil)
        }

        plog("resolveStation: kein verwendbares Ergebnis gefunden")
        return nil
    }

    // MARK: - Station Quays (Koordinaten pro Steig)

    func getStationQuays(hafasID: String, accessToken: String) async -> [StationQuay] {
        let safeID = sanitize(hafasID)
        let query = """
        {
          station(id: "\(safeID)") {
            platforms(first: 50) {
              elements {
                ... on Platform {
                  id
                  label
                  location {
                    lat
                    long
                  }
                }
              }
            }
          }
        }
        """

        guard let data = try? await executeQuery(query: query, accessToken: accessToken),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let stationObj = responseData["station"] as? [String: Any],
              let platformsObj = stationObj["platforms"] as? [String: Any],
              let elements = platformsObj["elements"] as? [[String: Any]]
        else {
            plog("getStationQuays: Keine Platform-Daten für hafasID=\(hafasID)")
            return []
        }

        let quays: [StationQuay] = elements.compactMap { platform in
            guard let id = platform["id"] as? String,
                  let label = platform["label"] as? String, !label.isEmpty,
                  let locationObj = platform["location"] as? [String: Any],
                  let lat = locationObj["lat"] as? Double,
                  let lon = locationObj["long"] as? Double,
                  lat != 0, lon != 0 else { return nil }
            return StationQuay(
                id: id,
                name: "Steig \(label)",
                letter: label,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
            )
        }

        plog("getStationQuays: \(quays.count) Steige für hafasID=\(hafasID)")

#if DEBUG
        print("🗺️ [Quays] Alle Platforms für hafasID=\(hafasID):")
        for platform in elements {
            let id = platform["id"] as? String ?? "–"
            let label = platform["label"] as? String ?? "–"
            let loc = platform["location"] as? [String: Any]
            let lat = loc?["lat"] as? Double ?? 0
            let lon = loc?["long"] as? Double ?? 0
            print("   id=\(id) label=\"\(label)\" lat=\(lat) lon=\(lon)")
        }
#endif

        return quays
    }
}
