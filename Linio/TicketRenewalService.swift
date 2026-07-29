//
//  TicketRenewalService.swift
//  Linio
//

import Foundation
import UserNotifications

enum ExpiryBadgeState {
    case warning(days: Int)  // 1–3 Tage bis Ablauf
    case urgent              // Läuft heute ab (0 Tage)
    case expired             // Bereits abgelaufen
}

final class TicketRenewalService {
    static let shared = TicketRenewalService()
    private init() {}

    private let notificationIDEarly = "ticket-renewal-early"
    private let notificationIDFinal = "ticket-renewal-final"
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

    /// Gibt die Anzahl der verbleibenden Tage zurück (negativ = abgelaufen, 0 = heute).
    func daysUntilExpiry(for ticket: DeutschlandTicket) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let expiry = cal.startOfDay(for: ticket.validUntil)
        return cal.dateComponents([.day], from: today, to: expiry).day ?? 0
    }

    /// Gibt den anzuzeigenden Badge-Zustand zurück, oder nil wenn kein Badge nötig.
    func expiryBadgeState(for ticket: DeutschlandTicket) -> ExpiryBadgeState? {
        let days = daysUntilExpiry(for: ticket)
        switch days {
        case ..<0:      return .expired
        case 0:         return .urgent
        case 1...3:     return .warning(days: days)
        default:        return nil
        }
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
    func scheduleRenewalNotification(for ticket: DeutschlandTicket) async {
        cancelRenewalNotification()
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        let updatedSettings = await center.notificationSettings()
        guard updatedSettings.authorizationStatus == .authorized ||
              updatedSettings.authorizationStatus == .provisional else { return }
        let cal = Calendar.current
        let now = Date()
        guard cal.compare(ticket.validUntil, to: now, toGranularity: .day) != .orderedAscending else { return }

        // Final: letzter Gültigkeitstag 09:00
        var finalComps = cal.dateComponents([.year, .month, .day], from: ticket.validUntil)
        finalComps.hour = 9
        finalComps.minute = 0

        let finalContent = UNMutableNotificationContent()
        finalContent.title = "Deutschlandticket läuft heute ab"
        finalContent.body = "Hast du für \(nextMonthName(from: ticket.validUntil)) verlängert? Jetzt in der App aktualisieren."
        finalContent.sound = .default

        let finalTrigger = UNCalendarNotificationTrigger(dateMatching: finalComps, repeats: false)
        let finalRequest = UNNotificationRequest(identifier: notificationIDFinal, content: finalContent, trigger: finalTrigger)
        UNUserNotificationCenter.current().add(finalRequest) { error in
            #if DEBUG
            if let error { print("❌ [RENEWAL] Final-Notification-Fehler: \(error)") }
            else { print("✅ [RENEWAL] Final-Notification geplant für \(finalComps.day ?? 0).\(finalComps.month ?? 0).\(finalComps.year ?? 0) 09:00") }
            #endif
        }

        // Early: 3 Tage vorher 09:00 — nur planen wenn noch in der Zukunft
        if let earlyDate = cal.date(byAdding: .day, value: -3, to: ticket.validUntil),
           cal.compare(earlyDate, to: now, toGranularity: .day) != .orderedAscending {
            var earlyComps = cal.dateComponents([.year, .month, .day], from: earlyDate)
            earlyComps.hour = 9
            earlyComps.minute = 0

            let earlyContent = UNMutableNotificationContent()
            earlyContent.title = "Deutschlandticket läuft bald ab"
            earlyContent.body = "Noch 3 Tage gültig. Hast du für \(nextMonthName(from: ticket.validUntil)) verlängert? Jetzt in der App aktualisieren."
            earlyContent.sound = .default

            let earlyTrigger = UNCalendarNotificationTrigger(dateMatching: earlyComps, repeats: false)
            let earlyRequest = UNNotificationRequest(identifier: notificationIDEarly, content: earlyContent, trigger: earlyTrigger)
            UNUserNotificationCenter.current().add(earlyRequest) { error in
                #if DEBUG
                if let error { print("❌ [RENEWAL] Early-Notification-Fehler: \(error)") }
                else { print("✅ [RENEWAL] Early-Notification geplant für \(earlyComps.day ?? 0).\(earlyComps.month ?? 0).\(earlyComps.year ?? 0) 09:00") }
                #endif
            }
        }
    }

    func cancelRenewalNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIDEarly, notificationIDFinal]
        )
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
        let request = UNNotificationRequest(identifier: notificationIDFinal, content: content, trigger: trigger)
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
