//
//  ConnectionShareService.swift
//  Linio
//
//  Service für das Teilen von Verbindungen als Text oder Deeplink
//

import Foundation
import SwiftUI

// MARK: - ConnectionShareService

struct ConnectionShareService {
    private static let formatter = DateFormattingHelper.shared
    private static let appScheme = "linio"
    
    // MARK: - Share Text Generation
    
    /// Generiert einen formatierten Share-Text für eine Verbindung
    static func generateShareText(for trip: DetailedTrip) -> String {
        var text = "🚆 Meine RNV Verbindung\n"
        text += "━━━━━━━━━━━━━━━━━━━━━\n\n"
        
        // Header mit Zeiten
        let depTime = formatter.formatTime(trip.startTime)
        let arrTime = formatter.formatTime(trip.endTime)
        let duration = formatter.calculateDuration(start: trip.startTime, end: trip.endTime)
        let date = formatter.formatDateShort(formatter.parseISO8601(trip.startTime) ?? Date())
        
        text += "📅 \(date)\n"
        text += "⏱️ \(depTime) → \(arrTime) (\(duration))\n\n"
        
        // Legs
        for (index, leg) in trip.legs.enumerated() {
            if leg.isTimedLeg {
                let lineName = TransportIconHelper.getShortLineName(from: leg.serviceName)
                let emoji = getTransportEmoji(for: leg.serviceType)
                
                text += "\(emoji) \(lineName) → \(leg.destinationLabel ?? "")\n"
                text += "   📍 \(formatter.formatTime(leg.departureTime ?? "")) \(leg.boardStopName ?? "")\n"
                text += "   📍 \(formatter.formatTime(leg.arrivalTime ?? "")) \(leg.alightStopName ?? "")\n"
                
                // Füge Umsteigehinweis hinzu wenn nicht letztes Leg
                if index < trip.legs.count - 1 {
                    let nextLeg = trip.legs[index + 1]
                    if nextLeg.type == .continuousLeg {
                        text += "\n"
                    }
                }
            } else if leg.type == .continuousLeg {
                let walkDuration = formatter.calculateDuration(
                    start: leg.departureTime ?? "",
                    end: leg.arrivalTime ?? ""
                )
                text += "🚶 Fußweg (\(walkDuration))\n\n"
            }
        }
        
        // Footer
        if trip.interchanges > 0 {
            text += "\n🔄 \(trip.interchanges) Umstieg\(trip.interchanges == 1 ? "" : "e")"
        } else {
            text += "\n✨ Direktverbindung"
        }
        
        text += "\n\n━━━━━━━━━━━━━━━━━━━━━\n"
        text += "📱 Geteilt mit Linio"
        
        return text
    }
    
    /// Generiert einen kompakten Share-Text (für Messenger)
    static func generateCompactShareText(for trip: DetailedTrip) -> String {
        let depTime = formatter.formatTime(trip.startTime)
        let arrTime = formatter.formatTime(trip.endTime)
        
        guard let firstLeg = trip.legs.first(where: { $0.isTimedLeg }),
              let lastLeg = trip.legs.last(where: { $0.isTimedLeg }) else {
            return "🚆 RNV Verbindung: \(depTime) → \(arrTime)"
        }
        
        let origin = firstLeg.boardStopName ?? "Start"
        let destination = lastLeg.alightStopName ?? "Ziel"
        
        var text = "🚆 \(origin) → \(destination)\n"
        text += "⏱️ \(depTime) - \(arrTime)"
        
        if trip.interchanges > 0 {
            text += " (\(trip.interchanges)x 🔄)"
        }
        
        return text
    }
    
    // MARK: - Deeplink Generation
    
    /// Generiert einen Deeplink für die Verbindung
    static func generateDeeplink(for trip: DetailedTrip) -> URL? {
        guard let firstLeg = trip.legs.first(where: { $0.isTimedLeg }),
              let lastLeg = trip.legs.last(where: { $0.isTimedLeg }),
              let boardStop = firstLeg.boardStopName,
              let alightStop = lastLeg.alightStopName else {
            return nil
        }
        
        var components = URLComponents()
        components.scheme = appScheme
        components.host = "connection"
        components.queryItems = [
            URLQueryItem(name: "from", value: boardStop),
            URLQueryItem(name: "to", value: alightStop),
            URLQueryItem(name: "time", value: trip.startTime)
        ]
        
        return components.url
    }
    
    // MARK: - Helper
    
    private static func getTransportEmoji(for serviceType: String?) -> String {
        let type = (serviceType ?? "").uppercased()
        if type.contains("STRASSENBAHN") || type.contains("TRAM") {
            return "🚊"
        } else if type.contains("BUS") {
            return "🚌"
        } else if type.contains("S-BAHN") || type.contains("SBAHN") {
            return "🚆"
        } else if type.contains("REGIONALBAHN") || type.contains("RB") {
            return "🚂"
        }
        return "🚇"
    }
}

// MARK: - ShareableTrip (für ShareLink)

struct ShareableTrip: Transferable {
    let trip: DetailedTrip
    let shareText: String
    
    init(trip: DetailedTrip) {
        self.trip = trip
        self.shareText = ConnectionShareService.generateShareText(for: trip)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.shareText)
    }
}
