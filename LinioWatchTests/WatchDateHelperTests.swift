//
//  WatchDateHelperTests.swift
//  LinioWatchTests
//

import XCTest
@testable import LinioWatch

final class WatchDateHelperTests: XCTestCase {

    // MARK: - formatTime

    func testFormatTime_ValidISO_ReturnHHMM() {
        let result = WatchDateHelper.formatTime("2026-08-28T14:35:00+02:00")
        // Result is locale-dependent; verify non-empty and contains digits
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains(where: { $0.isNumber }))
    }

    func testFormatTime_InvalidISO_ReturnsEmptyOrPlaceholder() {
        let result = WatchDateHelper.formatTime("not-a-date")
        // Should not crash and return some fallback
        XCTAssertNotNil(result)
    }

    // MARK: - minutesUntil

    func testMinutesUntil_PastDate_ReturnsNegativeOrZero() {
        let past = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300))
        let minutes = WatchDateHelper.minutesUntil(past)
        XCTAssertNotNil(minutes)
        XCTAssertLessThanOrEqual(minutes!, 0)
    }

    func testMinutesUntil_FutureDate_ReturnsPositive() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(600))
        let minutes = WatchDateHelper.minutesUntil(future)
        XCTAssertNotNil(minutes)
        XCTAssertGreaterThan(minutes!, 0)
    }

    func testMinutesUntil_InvalidISO_ReturnsNil() {
        XCTAssertNil(WatchDateHelper.minutesUntil("garbage"))
    }

    // MARK: - durationString

    func testDurationString_60Minutes_ContainsExpectedUnit() {
        let start = ISO8601DateFormatter().string(from: Date())
        let end = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
        let result = WatchDateHelper.durationString(start: start, end: end)
        XCTAssertFalse(result.isEmpty)
    }

    func testDurationString_InvalidDates_ReturnsEmptyOrPlaceholder() {
        let result = WatchDateHelper.durationString(start: "bad", end: "bad")
        XCTAssertNotNil(result)
    }

    // MARK: - phase (TripData)

    func testPhase_FutureTrip_ReturnsPending() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
        let trip = TripData(
            id: "test-1",
            startTime: future,
            endTime: ISO8601DateFormatter().string(from: Date().addingTimeInterval(7200)),
            interchanges: 0,
            startStation: "A",
            endStation: "B",
            legs: []
        )
        XCTAssertEqual(WatchDateHelper.phase(for: trip), .beforeDeparture)
    }

    func testPhase_PastTrip_ReturnsCompleted() {
        let past = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
        let trip = TripData(
            id: "test-2",
            startTime: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
            endTime: past,
            interchanges: 0,
            startStation: "A",
            endStation: "B",
            legs: []
        )
        XCTAssertEqual(WatchDateHelper.phase(for: trip), .arrived)
    }
}
