//
//  GraphQLService+Departures.swift
//  Linio
//
//  Abfahrten werden über zwei Wege ermittelt:
//  1. Primär: native journeys-API (hafasID erforderlich, liefert Auslastung)
//  2. Fallback: Hub-Workaround – Verbindungen zu Hauptknotenpunkten, erster TimedLeg = Abfahrt

import Foundation

extension GraphQLService {

    // MARK: - Departures

    func getDepartures(station: Station, accessToken: String, time: String? = nil) async -> DeparturesResult {
        let searchTime = time ?? DateFormattingHelper.shared.formatISO8601(Date())

        // Primär: native journeys-API mit Auslastung (erfordert hafasID)
        if !station.hafasID.isEmpty {
            plog("getDepartures: versuche Journeys-API mit hafasID=\(station.hafasID)")
            let journeysResult = await getDeparturesViaJourneys(hafasID: station.hafasID, accessToken: accessToken, time: searchTime)
            plog("getDepartures: Journeys-API → \(journeysResult.departures.count) Abfahrten, Fehler=\(journeysResult.error?.errorDescription ?? "–")")
            if !journeysResult.departures.isEmpty {
                return journeysResult
            }
            if Task.isCancelled {
                return DeparturesResult(departures: [], error: nil)
            }
        }

        // Fallback: hub-workaround (wenn journeys keine Daten liefert)
        let cacheExpired = Self.cachedHubIDsDate.map { Date().timeIntervalSince($0) > Self.hubIDsCacheTTL } ?? true
        if Self.cachedHubIDs.isEmpty || cacheExpired {
            plog("getDepartures: resolveHubIDs wird ausgeführt")
            await resolveHubIDs(accessToken: accessToken)
            plog("getDepartures: cachedHubIDs=[\(Self.cachedHubIDs.joined(separator: ","))]")
        }

        let hubs = Self.cachedHubIDs.filter { $0 != station.globalID }
        guard !hubs.isEmpty else {
            plog("getDepartures: keine Hubs verfügbar")
            return DeparturesResult(departures: [], error: .noData)
        }

        var allDepartures: [Departure] = []

        for hubID in hubs.prefix(3) {
            let deps = await fetchFirstLegsAsDepartures(from: station.globalID, to: hubID, time: searchTime, accessToken: accessToken)
            plog("getDepartures: Hub \(hubID) → \(deps.count) Abfahrten")
            allDepartures.append(contentsOf: deps)
        }

        var seen = Set<String>()
        var result = allDepartures.filter { seen.insert("\($0.lineName)-\($0.scheduledDeparture)").inserted }
        result.sort {
            let fmt = DateFormattingHelper.shared
            guard let a = fmt.parseISO8601($0.scheduledDeparture),
                  let b = fmt.parseISO8601($1.scheduledDeparture) else { return false }
            return a < b
        }

        return DeparturesResult(departures: result, error: result.isEmpty ? .noData : nil)
    }

    /// Kompatibilitäts-Überladung für Watch-Connectivity (hat nur globalID, kein hafasID)
    func getDepartures(globalID: String, accessToken: String, time: String? = nil) async -> DeparturesResult {
        let station = Station(hafasID: "", globalID: globalID, longName: "", latitude: nil, longitude: nil)
        return await getDepartures(station: station, accessToken: accessToken, time: time)
    }

    // MARK: - Full Departure Route

    /// Fetches all intermediate stops and the final stop of a departure all the way to its terminus.
    /// Falls back to an empty result if the terminus station cannot be resolved or the trip is not found.
    func fetchFullDepartureRoute(
        originID: String,
        direction: String,
        lineName: String,
        scheduledDeparture: String,
        accessToken: String
    ) async -> (intermediates: [DepartureStop], finalStop: DepartureStop?) {
        guard let terminus = await silentSearchStation(name: direction, accessToken: accessToken) else {
            return ([], nil)
        }
        let deps = await fetchFirstLegsAsDepartures(
            from: originID,
            to: terminus.globalID,
            time: scheduledDeparture,
            accessToken: accessToken
        )
        guard let match = deps.first(where: { $0.lineName == lineName }) else {
            return ([], nil)
        }
        return (match.intermediateStops, match.finalStop)
    }

    // MARK: - Departures via station(id).journeys (native API mit Auslastung)

    func getDeparturesViaJourneys(hafasID: String, accessToken: String, time: String) async -> DeparturesResult {
        let safeID = sanitize(hafasID)
        let safeTime = sanitize(time)

        let query = """
        {
          station(id: "\(safeID)") {
            journeys(startTime: "\(safeTime)", first: 30) {
              elements {
                ... on Journey {
                  id
                  line {
                    id
                  }
                  loads(onlyHafasID: "\(safeID)") {
                    loadType
                    ratio
                  }
                  boardStops: stops(onlyHafasID: "\(safeID)") {
                    plannedDeparture {
                      isoString
                    }
                    realtimeDeparture {
                      isoString
                    }
                    pole {
                      platform {
                        label
                      }
                    }
                  }
                  allStops: stops {
                    station {
                      longName
                    }
                    plannedDeparture {
                      isoString
                    }
                    realtimeDeparture {
                      isoString
                    }
                  }
                }
              }
            }
          }
        }
        """

        let data: Data
        do {
            data = try await executeQuery(query: query, accessToken: accessToken)
        } catch {
            plog("getDeparturesViaJourneys: Fehler für hafasID=\(hafasID) – \(error.localizedDescription)")
            return DeparturesResult(departures: [], error: NetworkError.from(error))
        }

        if let gqlError = extractGraphQLErrors(from: data) {
            plog("getDeparturesViaJourneys: GraphQL-Fehler – \(gqlError.errorDescription ?? "")")
            return DeparturesResult(departures: [], error: gqlError)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let stationObj = responseData["station"] as? [String: Any],
              let journeysObj = stationObj["journeys"] as? [String: Any],
              let elements = journeysObj["elements"] as? [[String: Any]]
        else {
            let snippet = String(data: data.prefix(400), encoding: .utf8) ?? "?"
            plog("getDeparturesViaJourneys: JSON-Parse fehlgeschlagen – \(snippet)")
            return DeparturesResult(departures: [], error: .noData)
        }

        plog("getDeparturesViaJourneys: \(elements.count) Journey-Elemente für hafasID=\(hafasID)")

        #if DEBUG
        if let firstEl = elements.first,
           let dumpData = try? JSONSerialization.data(withJSONObject: firstEl, options: .prettyPrinted),
           let dumpStr = String(data: dumpData, encoding: .utf8) {
            print("🔍 [Journeys] Erstes Element (hafasID=\(hafasID)):\n\(dumpStr)")
        }
        for (i, el) in elements.prefix(5).enumerated() {
            if let stops = el["boardStops"] as? [[String: Any]],
               let fs = stops.first {
                let poleObj = fs["pole"] as? [String: Any]
                let label = (poleObj?["platform"] as? [String: Any])?["label"] as? String ?? "–"
                let lineID = (el["line"] as? [String: Any])?["id"] as? String ?? "–"
                print("🚏 [Journeys] Journey[\(i)] line=\(lineID) platform.label=\(label)")
            }
        }
        #endif

        let departures: [Departure] = elements.compactMap { element -> Departure? in
            guard let lineObj = element["line"] as? [String: Any],
                  let lineID = lineObj["id"] as? String,
                  let stopsArr = element["boardStops"] as? [[String: Any]],
                  let firstStop = stopsArr.first,
                  let plannedObj = firstStop["plannedDeparture"] as? [String: Any],
                  let planned = plannedObj["isoString"] as? String,
                  planned != "null", !planned.isEmpty
            else { return nil }

            let realtime = (firstStop["realtimeDeparture"] as? [String: Any])?["isoString"] as? String
            let effectiveRealtime = (realtime == "null" || realtime?.isEmpty == true) ? nil : realtime

            // line.id Format: "rnv:64:H" → ["rnv", "64", "H"]
            let parts = lineID.split(separator: ":").map(String.init)
            let lineName = parts.count >= 2 ? parts[1] : lineID

            // ServiceType aus Linienname ableiten (RNV-spezifisch)
            let serviceType: String? = {
                let n = lineName.uppercased()
                if n.hasPrefix("S") && n.dropFirst().first?.isNumber == true { return "S_BAHN" }
                let numericPrefix = n.prefix(while: { $0.isNumber })
                if !numericPrefix.isEmpty, let num = Int(numericPrefix), num >= 1, num <= 61 { return "STRASSENBAHN" }
                return "BUS"
            }()

            // Letzter Halt aus allStops als Richtung
            let allStops = element["allStops"] as? [[String: Any]] ?? []
            let destinationName = allStops.last.flatMap {
                ($0["station"] as? [String: Any])?["longName"] as? String
            } ?? ""

            // Auslastung
            var occupancy: OccupancyLevel? = nil
            if let loadsArr = element["loads"] as? [[String: Any]],
               let firstLoad = loadsArr.first,
               let loadType = firstLoad["loadType"] as? String {
                occupancy = OccupancyLevel(from: loadType)
            }

            let poleObj = firstStop["pole"] as? [String: Any]
            let platformLabel = (poleObj?["platform"] as? [String: Any])?["label"] as? String
            let quayText = platformLabel.map { "Steig \($0)" }
            plog("getDeparturesViaJourneys: Linie \(lineName) platform.label=\(platformLabel ?? "–") quayText=\(quayText ?? "–")")

            // allStops → boardStopName + intermediateStops + finalStop
            let boardTime = planned
            var seenBoard = false
            var boardStopName: String? = nil
            var intermediateStops: [DepartureStop] = []
            var finalStop: DepartureStop? = nil

            for stop in allStops {
                guard let stationObj = stop["station"] as? [String: Any],
                      let name = stationObj["longName"] as? String,
                      !name.isEmpty, name != "null" else { continue }

                let rawPlanned = (stop["plannedDeparture"] as? [String: Any])?["isoString"] as? String
                let stopPlanned: String? = (rawPlanned == "null" || rawPlanned?.isEmpty == true) ? nil : rawPlanned
                let rawRealtime = (stop["realtimeDeparture"] as? [String: Any])?["isoString"] as? String
                let stopRealtime: String? = (rawRealtime == "null" || rawRealtime?.isEmpty == true) ? nil : rawRealtime

                if !seenBoard {
                    if stopPlanned == boardTime {
                        seenBoard = true
                        boardStopName = name
                    }
                    continue
                }
                intermediateStops.append(DepartureStop(name: name, scheduledTime: stopPlanned, estimatedTime: stopRealtime))
            }

            if !intermediateStops.isEmpty {
                finalStop = intermediateStops.removeLast()
            }

            var departure = Departure(
                scheduledDeparture: planned,
                estimatedDeparture: effectiveRealtime,
                lineName: lineName,
                direction: destinationName,
                serviceType: serviceType,
                boardStopName: boardStopName,
                intermediateStops: intermediateStops,
                finalStop: finalStop,
                occupancy: occupancy
            )
            departure.quayText = quayText
            return departure
        }

        return DeparturesResult(departures: departures, error: departures.isEmpty ? .noData : nil)
    }

    // MARK: - Private Helpers

    private func resolveHubIDs(accessToken: String) async {
        var ids: [String] = []
        for name in AppConfiguration.hubStationNames {
            if let station = await silentSearchStation(name: name, accessToken: accessToken) {
                ids.append(station.globalID)
            }
        }
        Self.cachedHubIDs = ids
        Self.cachedHubIDsDate = Date()
    }

    private func silentSearchStation(name: String, accessToken: String) async -> Station? {
        let safeName = sanitize(name)
        let query = """
        {
          stations(first: 1, name: "\(safeName)") {
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
        guard let data = try? await executeQuery(query: query, accessToken: accessToken),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let stationsObj = responseData["stations"] as? [String: Any],
              let elements = stationsObj["elements"] as? [[String: Any]],
              let first = elements.first,
              let hafasID = first["hafasID"] as? String,
              let globalID = first["globalID"] as? String,
              let longName = first["longName"] as? String
        else { return nil }
        let locationObj = first["location"] as? [String: Any]
        let lat = locationObj?["lat"] as? Double
        let lon = locationObj?["long"] as? Double
        return Station(hafasID: hafasID, globalID: globalID, longName: longName, latitude: lat, longitude: lon)
    }

    private func fetchFirstLegsAsDepartures(from originID: String, to destID: String, time: String, accessToken: String) async -> [Departure] {
        let query = """
        {
          trips(
            originGlobalID: "\(sanitize(originID))"
            destinationGlobalID: "\(sanitize(destID))"
            departureTime: "\(sanitize(time))"
          ) {
            legs {
              ... on TimedLeg {
                board {
                  point {
                    ... on StopPoint {
                      stopPointName
                      ref
                      station {
                        location {
                          lat
                          long
                        }
                      }
                    }
                  }
                  timetabledTime { isoString }
                  estimatedTime { isoString }
                }
                alight {
                  point {
                    ... on StopPoint {
                      stopPointName
                      station {
                        location {
                          lat
                          long
                        }
                      }
                    }
                  }
                  timetabledTime { isoString }
                  estimatedTime { isoString }
                }
                legIntermediates {
                  point {
                    ... on StopPoint {
                      stopPointName
                      station {
                        location {
                          lat
                          long
                        }
                      }
                    }
                  }
                }
                service {
                  name
                  type
                  destinationLabel
                }
              }
            }
          }
        }
        """

        let hubData: Data
        do {
            hubData = try await executeQuery(query: query, accessToken: accessToken)
        } catch {
            plog("fetchFirstLegsAsDepartures: Fehler von=\(originID) zu=\(destID) – \(error.localizedDescription)")
            return []
        }
        guard let json = try? JSONSerialization.jsonObject(with: hubData) as? [String: Any],
              let responseData = json["data"] as? [String: Any],
              let trips = responseData["trips"] as? [[String: Any]]
        else { return [] }

        return trips.compactMap { trip -> Departure? in
            guard let legs = trip["legs"] as? [[String: Any]],
                  let firstTimedLeg = legs.first(where: { $0["board"] != nil }),
                  let board = firstTimedLeg["board"] as? [String: Any],
                  let service = firstTimedLeg["service"] as? [String: Any],
                  let lineName = service["name"] as? String,
                  let direction = service["destinationLabel"] as? String,
                  let timetabled = (board["timetabledTime"] as? [String: Any])?["isoString"] as? String,
                  timetabled != "null", !timetabled.isEmpty
            else { return nil }

            let estimated = (board["estimatedTime"] as? [String: Any])?["isoString"] as? String
            let rawBoardStop = (board["point"] as? [String: Any])?["stopPointName"] as? String
            let boardStopName: String? = (rawBoardStop == "null" || rawBoardStop?.isEmpty == true) ? nil : rawBoardStop

            let alight = firstTimedLeg["alight"] as? [String: Any]
            let rawAlightName = (alight?["point"] as? [String: Any])?["stopPointName"] as? String
            let alightName: String? = (rawAlightName == "null" || rawAlightName?.isEmpty == true) ? nil : rawAlightName
            let alightTimetabled = (alight?["timetabledTime"] as? [String: Any])?["isoString"] as? String
            let alightEstimated = (alight?["estimatedTime"] as? [String: Any])?["isoString"] as? String
            let finalStop = alightName.map {
                DepartureStop(
                    name: $0,
                    scheduledTime: (alightTimetabled == "null") ? nil : alightTimetabled,
                    estimatedTime: (alightEstimated == "null") ? nil : alightEstimated
                )
            }

            let rawIntermediates = firstTimedLeg["legIntermediates"] as? [[String: Any]] ?? []
            let intermediateStops: [DepartureStop] = rawIntermediates.compactMap { stop in
                guard let point = stop["point"] as? [String: Any],
                      let name = point["stopPointName"] as? String,
                      name != "null", !name.isEmpty else { return nil }
                return DepartureStop(name: name, scheduledTime: nil, estimatedTime: nil)
            }

            let boardRef = (board["point"] as? [String: Any])?["ref"] as? String
            let quayText = boardRef.flatMap { StationQuay.quayText(fromRef: $0) }

            var departure = Departure(
                scheduledDeparture: timetabled,
                estimatedDeparture: (estimated == "null") ? nil : estimated,
                lineName: lineName,
                direction: direction,
                serviceType: service["type"] as? String,
                boardStopName: boardStopName,
                intermediateStops: intermediateStops,
                finalStop: finalStop,
                originGlobalID: originID
            )
            departure.quayText = quayText
            return departure
        }
    }
}
