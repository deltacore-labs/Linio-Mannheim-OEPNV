//
//  NotificationService.swift
//  RNV-Transport-App
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func schedule(trip: TripData, minutesBefore: Int) {
        guard let departureDate = DateFormattingHelper.shared.parseISO8601(trip.startTime) else { return }
        let timeInterval = departureDate.timeIntervalSinceNow - Double(minutesBefore * 60)
        guard timeInterval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Abfahrt in \(minutesBefore) Min"

        let firstLeg = trip.legs.first(where: { $0.legType != "continuousLeg" })
        let line = firstLeg?.serviceName ?? ""
        let direction = firstLeg?.destinationLabel ?? trip.endStation
        let time = DateFormattingHelper.shared.formatTime(trip.startTime)
        content.body = "\(line) Richtung \(direction) – \(time) Uhr von \(trip.startStation)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: trip.id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("❌ [NOTIF] Fehler beim Planen: \(error)")
            } else {
                print("✅ [NOTIF] Geplant für \(String(trip.id.prefix(8))) in \(Int(timeInterval))s")
            }
            #endif
        }
    }

    func cancel(tripId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [tripId])
        #if DEBUG
        print("✅ [NOTIF] Abgebrochen: \(String(tripId.prefix(8)))")
        #endif
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #if DEBUG
        print("✅ [NOTIF] Alle ausstehenden Notifications abgebrochen")
        #endif
    }
}
