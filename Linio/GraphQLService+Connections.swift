//
//  GraphQLService+Connections.swift
//  Linio
//

import Foundation

extension GraphQLService {

    // MARK: - Get Connections

    func getConnections(fromGlobalID: String, toGlobalID: String, accessToken: String, departureTime: String? = nil, arrivalTime: String? = nil, mode: ConnectionLoadingMode = .replace) async {
        isLoading = true
        lastError = nil

        do {
            let newTrips = try await fetchTrips(fromGlobalID: fromGlobalID, toGlobalID: toGlobalID, accessToken: accessToken, departureTime: departureTime, arrivalTime: arrivalTime)
            switch mode {
            case .replace: self.detailedTrips = newTrips
            case .prepend:
                self.detailedTrips = newTrips + self.detailedTrips
                if self.detailedTrips.count > 50 { self.detailedTrips = Array(self.detailedTrips.prefix(50)) }
            case .append:
                self.detailedTrips.append(contentsOf: newTrips)
                if self.detailedTrips.count > 50 { self.detailedTrips = Array(self.detailedTrips.suffix(50)) }
            }
        } catch {
            lastError = NetworkError.from(error)
        }

        isLoading = false
    }

    /// Führt die Verbindungssuche aus und gibt die Ergebnisse direkt zurück, ohne den
    /// @Published-State zu verändern. Wird von PhoneConnectivityManager für Watch-Anfragen genutzt.
    func fetchConnectionsForWatch(fromGlobalID: String, toGlobalID: String, accessToken: String) async -> [TripData] {
        let trips = (try? await fetchTrips(fromGlobalID: fromGlobalID, toGlobalID: toGlobalID, accessToken: accessToken)) ?? []
        return trips.map { trip in
            TripData(
                id: trip.id.uuidString,
                startTime: trip.startTime,
                endTime: trip.endTime,
                interchanges: trip.interchanges,
                startStation: trip.legs.first(where: { $0.isTimedLeg })?.boardStopName ?? "",
                endStation: trip.legs.last(where: { $0.isTimedLeg })?.alightStopName ?? "",
                legs: trip.legs.map { leg in
                    TripLegData(
                        legType: leg.type.rawValue,
                        boardStopName: leg.boardStopName,
                        alightStopName: leg.alightStopName,
                        departureTime: leg.departureTime,
                        arrivalTime: leg.arrivalTime,
                        serviceName: leg.serviceName,
                        serviceType: leg.serviceType,
                        destinationLabel: leg.destinationLabel,
                        intermediateStopNames: leg.intermediateStops.isEmpty ? nil : leg.intermediateStops.map { $0.name }
                    )
                }
            )
        }
    }

    private func fetchTrips(fromGlobalID: String, toGlobalID: String, accessToken: String, departureTime: String? = nil, arrivalTime: String? = nil) async throws -> [DetailedTrip] {
        let safeFrom = sanitize(fromGlobalID)
        let safeTo = sanitize(toGlobalID)

        let timeArgument: String
        if let arrival = arrivalTime {
            timeArgument = "arrivalTime: \"\(sanitize(arrival))\""
        } else {
            let t = departureTime ?? DateFormattingHelper.shared.formatISO8601(Date())
            timeArgument = "departureTime: \"\(sanitize(t))\""
        }

        #if DEBUG
        print("🔍 [GraphQL] getConnections aufgerufen:")
        print("   originGlobalID: \(safeFrom)")
        print("   destinationGlobalID: \(safeTo)")
        print("   \(timeArgument)")
        #endif

        let query = """
        {
          trips(
            originGlobalID: "\(safeFrom)"
            destinationGlobalID: "\(safeTo)"
            \(timeArgument)
          ) {
            startTime {
              isoString
            }
            endTime {
              isoString
            }
            interchanges
            legs {
              ... on InterchangeLeg {
                mode
              }
              ... on ContinuousLeg {
                mode
              }
              ... on TimedLeg {
                board {
                  point {
                    ... on StopPoint {
                      ref
                      stopPointName
                      station {
                        location {
                          lat
                          long
                        }
                      }
                    }
                  }
                  estimatedTime {
                    isoString
                  }
                  timetabledTime {
                    isoString
                  }
                }
                alight {
                  point {
                    ... on StopPoint {
                      ref
                      stopPointName
                      station {
                        location {
                          lat
                          long
                        }
                      }
                    }
                  }
                  estimatedTime {
                    isoString
                  }
                  timetabledTime {
                    isoString
                  }
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
                  type
                  name
                  description
                  destinationLabel
                }
              }
            }
          }
        }
        """

        do {
            let data = try await executeQuery(query: query, accessToken: accessToken)

            #if DEBUG
            if let rawResponse = String(data: data, encoding: .utf8) {
                let preview = rawResponse.prefix(500)
                print("📦 [GraphQL] fetchTrips Antwort (\(data.count) bytes): \(preview)")
            }
            #endif

            if let gqlError = extractGraphQLErrors(from: data) {
                #if DEBUG
                print("❌ [GraphQL] Fehler in Antwort: \(gqlError.errorDescription ?? "")")
                #endif
                throw gqlError
            }

            if let responseData = parseResponseData(from: data),
               let trips = responseData["trips"] as? [[String: Any]] {
                #if DEBUG
                print("🚆 [GraphQL] \(trips.count) Trips gefunden")
                #endif

                let newTrips = trips.compactMap { trip -> DetailedTrip? in
                    guard let startTimeDict = trip["startTime"] as? [String: Any],
                          let startTime = startTimeDict["isoString"] as? String,
                          let endTimeDict = trip["endTime"] as? [String: Any],
                          let endTime = endTimeDict["isoString"] as? String,
                          let interchanges = trip["interchanges"] as? Int,
                          let legs = trip["legs"] as? [[String: Any]] else { return nil }

                    let parsedLegs = legs.compactMap { leg -> TripLeg? in
                        if let board = leg["board"] as? [String: Any],
                           let alight = leg["alight"] as? [String: Any],
                           let service = leg["service"] as? [String: Any] {

                            let boardPoint = board["point"] as? [String: Any]
                            let alightPoint = alight["point"] as? [String: Any]
                            let boardLocationObj = (boardPoint?["station"] as? [String: Any])?["location"] as? [String: Any]
                            let boardLat = boardLocationObj?["lat"] as? Double
                            let boardLon = boardLocationObj?["long"] as? Double
                            let alightLocationObj = (alightPoint?["station"] as? [String: Any])?["location"] as? [String: Any]
                            let alightLat = alightLocationObj?["lat"] as? Double
                            let alightLon = alightLocationObj?["long"] as? Double
                            let boardTimetabled = board["timetabledTime"] as? [String: Any]
                            let boardEstimated = board["estimatedTime"] as? [String: Any]
                            let alightTimetabled = alight["timetabledTime"] as? [String: Any]
                            let alightEstimated = alight["estimatedTime"] as? [String: Any]

                            let rawIntermediates = leg["legIntermediates"] as? [[String: Any]] ?? []
                            let parsedIntermediates: [IntermediateStop] = rawIntermediates.compactMap { intermediate in
                                guard let point = intermediate["point"] as? [String: Any],
                                      let name = point["stopPointName"] as? String
                                else { return nil }
                                let stationObj = point["station"] as? [String: Any]
                                let locObj = stationObj?["location"] as? [String: Any]
                                return IntermediateStop(
                                    name: name,
                                    scheduledTime: nil,
                                    estimatedTime: nil,
                                    occupancy: nil,
                                    latitude: locObj?["lat"] as? Double,
                                    longitude: locObj?["long"] as? Double
                                )
                            }

                            return TripLeg(
                                type: .timedLeg,
                                mode: nil,
                                boardStopName: boardPoint?["stopPointName"] as? String,
                                alightStopName: alightPoint?["stopPointName"] as? String,
                                departureTime: boardTimetabled?["isoString"] as? String,
                                arrivalTime: alightTimetabled?["isoString"] as? String,
                                estimatedDepartureTime: boardEstimated?["isoString"] as? String,
                                estimatedArrivalTime: alightEstimated?["isoString"] as? String,
                                serviceType: service["type"] as? String,
                                serviceName: service["name"] as? String,
                                serviceDescription: service["description"] as? String,
                                destinationLabel: service["destinationLabel"] as? String,
                                intermediateStops: parsedIntermediates,
                                boardRef: boardPoint?["ref"] as? String,
                                boardLatitude: boardLat,
                                boardLongitude: boardLon,
                                alightLatitude: alightLat,
                                alightLongitude: alightLon
                            )
                        } else if let legMode = leg["mode"] as? String {
                            return TripLeg(
                                type: legMode == "WALK" ? .continuousLeg : .interchangeLeg,
                                mode: legMode,
                                boardStopName: nil,
                                alightStopName: nil,
                                departureTime: nil,
                                arrivalTime: nil,
                                estimatedDepartureTime: nil,
                                estimatedArrivalTime: nil,
                                serviceType: nil,
                                serviceName: legMode == "WALK" ? "Fußweg" : "Umstieg",
                                serviceDescription: nil,
                                destinationLabel: nil
                            )
                        }
                        return nil
                    }

                    return DetailedTrip(
                        startTime: startTime,
                        endTime: endTime,
                        interchanges: interchanges,
                        legs: parsedLegs
                    )
                }
                return newTrips
            }
        }
        throw NetworkError.unknown(message: "Fehler beim Laden der Verbindungen")
    }

    // MARK: - Occupancy Enrichment für Verbindungen

    func enrichConnectionsWithOccupancy(accessToken: String) async {
        let trips = detailedTrips
        guard !trips.isEmpty else { return }

        // Sammle unique (hafasID, departureTime) Paare aus allen TimedLegs
        var uniqueStationTimes: [(hafasID: String, depTime: String)] = []
        for trip in trips {
            for leg in trip.legs where leg.isTimedLeg {
                guard let ref = leg.boardRef,
                      let depTime = leg.departureTime else { continue }
                let parts = ref.split(separator: ":")
                guard parts.count >= 3 else { continue }
                let hafasID = String(parts[2])
                if !uniqueStationTimes.contains(where: { $0.hafasID == hafasID && $0.depTime == depTime }) {
                    uniqueStationTimes.append((hafasID, depTime))
                }
            }
        }

        // Alle Journeys parallel abfragen
        let stationTimeToJourneys: [String: [[String: Any]]] = await withTaskGroup(
            of: (String, [[String: Any]])?.self
        ) { group in
            for (hafasID, depTime) in uniqueStationTimes {
                let safeID = sanitize(hafasID)
                let safeTime = sanitize(depTime)
                let query = """
                {
                  station(id: "\(safeID)") {
                    journeys(startTime: "\(safeTime)", first: 10) {
                      elements {
                        ... on Journey {
                          line { id }
                          loads(onlyHafasID: "\(safeID)") {
                            loadType
                            ratio
                          }
                          stops(onlyHafasID: "\(safeID)") {
                            plannedDeparture { isoString }
                          }
                        }
                      }
                    }
                  }
                }
                """
                group.addTask {
                    guard let data = try? await self.executeQuery(query: query, accessToken: accessToken),
                          let responseData = self.parseResponseData(from: data),
                          let stationObj = responseData["station"] as? [String: Any],
                          let journeysObj = stationObj["journeys"] as? [String: Any],
                          let elements = journeysObj["elements"] as? [[String: Any]]
                    else { return nil }
                    return ("\(hafasID)|\(depTime)", elements)
                }
            }
            var result: [String: [[String: Any]]] = [:]
            for await pair in group {
                if let (key, elements) = pair { result[key] = elements }
            }
            return result
        }

        // Anreichern der Trips
        var enriched = trips
        for tripIdx in enriched.indices {
            var legs = enriched[tripIdx].legs
            for legIdx in legs.indices {
                var leg = legs[legIdx]
                guard leg.isTimedLeg,
                      let ref = leg.boardRef,
                      let depTime = leg.departureTime,
                      leg.occupancy == nil
                else { continue }

                let parts = ref.split(separator: ":")
                guard parts.count >= 3 else { continue }
                let hafasID = String(parts[2])

                guard let journeys = stationTimeToJourneys["\(hafasID)|\(depTime)"] else { continue }

                for journey in journeys {
                    guard let lineObj = journey["line"] as? [String: Any],
                          let lineID = lineObj["id"] as? String else { continue }

                    let journeyLineName = lineID.split(separator: ":").dropFirst().first.map(String.init) ?? lineID
                    guard journeyLineName == (leg.serviceName ?? "") else { continue }

                    if let stopsArr = journey["stops"] as? [[String: Any]],
                       let firstStop = stopsArr.first,
                       let plannedObj = firstStop["plannedDeparture"] as? [String: Any],
                       let planned = plannedObj["isoString"] as? String,
                       abs(isoTimeDiff(planned, depTime)) > 120 {
                        continue
                    }

                    if let loadsArr = journey["loads"] as? [[String: Any]],
                       let firstLoad = loadsArr.first,
                       let loadType = firstLoad["loadType"] as? String {
                        leg.occupancy = OccupancyLevel(from: loadType)
                    }
                    break
                }
                legs[legIdx] = leg
            }
            enriched[tripIdx] = DetailedTrip(
                startTime: enriched[tripIdx].startTime,
                endTime: enriched[tripIdx].endTime,
                interchanges: enriched[tripIdx].interchanges,
                legs: legs
            )
        }

        // Stale-Write-Schutz: nur schreiben wenn keine neuere getConnections-Antwort kam
        let currentIDs = Set(detailedTrips.map { $0.id })
        let snapshotIDs = Set(trips.map { $0.id })
        guard currentIDs == snapshotIDs else { return }

        detailedTrips = enriched
    }

    // Sekunden-Differenz zwischen zwei ISO-8601-Strings (|a - b|)
    private func isoTimeDiff(_ a: String, _ b: String) -> Double {
        let fmt = DateFormattingHelper.shared
        guard let da = fmt.parseISO8601(a), let db = fmt.parseISO8601(b) else { return Double.infinity }
        return da.timeIntervalSince(db)
    }
}
