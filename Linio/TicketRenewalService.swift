//
//  TicketRenewalService.swift
//  Linio
//

import Foundation
import UserNotifications

final class TicketRenewalService {
    static let shared = TicketRenewalService()
    private init() {}

    private let notificationID = "ticket-renewal"
    private let snoozeKey = "ticketRenewalSnoozedUntil"

    // MARK: - Public API

    /// Gibt true zurück wenn validUntil heute oder in der Vergangenheit liegt und kein Snooze aktiv ist.
    func isRenewalDue(for ticket: DeutschlandTicket) -> Bool {
        let cal = Calendar.current
        let now = Date()
        // Returns false if validUntil is strictly in the future (i.e. ticket is still valid)
        guard cal.compare(ticket.validUntil, to: now, toGranularity: .day) != .orderedDescending else {
            return false
        }
        if let snoozed = UserDefaults.standard.object(forKey: snoozeKey) as? Date, now < snoozed {
            return false
        }
        return true
    }

    /// Verschiebt validFrom/validUntil um genau einen Monat nach vorne.
    func advanceToNextMonth(_ ticket: DeutschlandTicket) -> DeutschlandTicket {
        let cal = Calendar.current
        var updated = ticket
        let firstOfCurrent = cal.date(from: cal.dateComponents([.year, .month], from: ticket.validFrom)) ?? ticket.validFrom
        guard let nextStart = cal.date(byAdding: .month, value: 1, to: firstOfCurrent) else { return ticket }
        updated.validFrom = nextStart
        updated.validUntil = lastDayOfMonth(for: nextStart)
        return updated
    }

    /// Plant eine Notification für den letzten Gültigkeitstag um 09:00.
    func scheduleRenewalNotification(for ticket: DeutschlandTicket) {
        cancelRenewalNotification()
        let cal = Calendar.current
        let now = Date()
        guard cal.compare(ticket.validUntil, to: now, toGranularity: .day) != .orderedAscending else { return }
        var comps = cal.dateComponents([.year, .month, .day], from: ticket.validUntil)
        comps.hour = 9
        comps.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Deutschlandticket läuft heute ab"
        content.body = "Hast du für \(nextMonthName(from: ticket.validUntil)) verlängert? Jetzt in der App aktualisieren."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error { print("❌ [RENEWAL] Notification-Fehler: \(error)") }
            else { print("✅ [RENEWAL] Notification geplant für \(comps.day!).\(comps.month!).\(comps.year!) 09:00") }
            #endif
        }
    }

    func cancelRenewalNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    /// Snooze: Nicht wieder fragen für 3 Tage.
    func snooze() {
        let snoozeUntil = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date().addingTimeInterval(3 * 24 * 3600)
        UserDefaults.standard.set(snoozeUntil, forKey: snoozeKey)
    }

    /// Snooze zurücksetzen (wird beim Verlängern aufgerufen).
    func clearSnooze() {
        UserDefaults.standard.removeObject(forKey: snoozeKey)
    }

    // MARK: - Debug

    #if DEBUG
    /// Feuert eine Renewal-Notification in `delay` Sekunden. Nur für Simulator-Tests.
    func scheduleTestNotification(in delay: TimeInterval = 5) {
        cancelRenewalNotification()
        let content = UNMutableNotificationContent()
        content.title = "Deutschlandticket läuft heute ab"
        content.body = "Test-Notification — Jetzt in der App aktualisieren."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in
            print("✅ [RENEWAL] Test-Notification in \(Int(delay))s geplant")
        }
    }
    #endif

    // MARK: - Helpers

    private func lastDayOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: date),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: date)) else { return date }
        return cal.date(byAdding: .day, value: range.count - 1, to: start) ?? date
    }

    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    func nextMonthName(from date: Date) -> String {
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .month, value: 1, to: date) else { return "nächsten Monat" }
        return monthFormatter.string(from: next)
    }
}
