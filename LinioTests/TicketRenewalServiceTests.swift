//
//  TicketRenewalServiceTests.swift
//  LinioTests
//
//  Unit Tests für TicketRenewalService
//

import XCTest
@testable import Linio

final class TicketRenewalServiceTests: XCTestCase {
    
    var sut: TicketRenewalService!
    
    override func setUp() {
        super.setUp()
        sut = TicketRenewalService.shared
        UserDefaults.standard.removeObject(forKey: "ticketRenewalSnoozedUntil")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "ticketRenewalSnoozedUntil")
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Helper
    
    private func createTicket(validFrom: Date, validUntil: Date) -> DeutschlandTicket {
        var ticket = DeutschlandTicket()
        ticket.validFrom = validFrom
        ticket.validUntil = validUntil
        return ticket
    }
    
    private func dateFromNow(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
    
    // MARK: - daysUntilExpiry Tests
    
    func test_daysUntilExpiry_whenExpiresInFuture_returnsPositiveDays() {
        let ticket = createTicket(validFrom: dateFromNow(days: -10), validUntil: dateFromNow(days: 5))
        XCTAssertEqual(sut.daysUntilExpiry(for: ticket), 5)
    }
    
    func test_daysUntilExpiry_whenExpiresToday_returnsZero() {
        let today = Calendar.current.startOfDay(for: Date())
        let ticket = createTicket(validFrom: dateFromNow(days: -30), validUntil: today)
        XCTAssertEqual(sut.daysUntilExpiry(for: ticket), 0)
    }
    
    func test_daysUntilExpiry_whenExpired_returnsNegativeDays() {
        let ticket = createTicket(validFrom: dateFromNow(days: -40), validUntil: dateFromNow(days: -3))
        XCTAssertEqual(sut.daysUntilExpiry(for: ticket), -3)
    }
    
    // MARK: - expiryBadgeState Tests
    
    func test_expiryBadgeState_whenExpired_returnsExpired() {
        let ticket = createTicket(validFrom: dateFromNow(days: -40), validUntil: dateFromNow(days: -1))
        if case .expired = sut.expiryBadgeState(for: ticket) { /* Success */ }
        else { XCTFail("Expected .expired state") }
    }
    
    func test_expiryBadgeState_whenExpiresToday_returnsUrgent() {
        let today = Calendar.current.startOfDay(for: Date())
        let ticket = createTicket(validFrom: dateFromNow(days: -30), validUntil: today)
        if case .urgent = sut.expiryBadgeState(for: ticket) { /* Success */ }
        else { XCTFail("Expected .urgent state") }
    }
    
    func test_expiryBadgeState_whenExpiresIn2Days_returnsWarning() {
        let ticket = createTicket(validFrom: dateFromNow(days: -28), validUntil: dateFromNow(days: 2))
        if case .warning(let days) = sut.expiryBadgeState(for: ticket) {
            XCTAssertEqual(days, 2)
        } else { XCTFail("Expected .warning state") }
    }
    
    func test_expiryBadgeState_whenExpiresIn10Days_returnsNil() {
        let ticket = createTicket(validFrom: dateFromNow(days: -20), validUntil: dateFromNow(days: 10))
        XCTAssertNil(sut.expiryBadgeState(for: ticket))
    }
    
    // MARK: - isRenewalDue Tests
    
    func test_isRenewalDue_whenTicketValid_returnsFalse() {
        let ticket = createTicket(validFrom: dateFromNow(days: -10), validUntil: dateFromNow(days: 5))
        XCTAssertFalse(sut.isRenewalDue(for: ticket))
    }
    
    func test_isRenewalDue_whenTicketExpired_returnsTrue() {
        let ticket = createTicket(validFrom: dateFromNow(days: -40), validUntil: dateFromNow(days: -1))
        XCTAssertTrue(sut.isRenewalDue(for: ticket))
    }
    
    // MARK: - Snooze Tests
    
    func test_snooze_setsSnoozeDateTo3DaysInFuture() {
        let beforeSnooze = Date()
        sut.snooze()
        let snoozedUntil = UserDefaults.standard.object(forKey: "ticketRenewalSnoozedUntil") as? Date
        XCTAssertNotNil(snoozedUntil)
        let expected = Calendar.current.date(byAdding: .day, value: 3, to: beforeSnooze)!
        XCTAssertLessThan(abs(snoozedUntil!.timeIntervalSince(expected)), 2)
    }
    
    func test_clearSnooze_removesSnoozeDate() {
        sut.snooze()
        sut.clearSnooze()
        XCTAssertNil(UserDefaults.standard.object(forKey: "ticketRenewalSnoozedUntil"))
    }
}
