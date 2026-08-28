//
//  WatchModelsTests.swift
//  LinioWatchTests
//

import XCTest
@testable import LinioWatch

final class WatchStyleHelperTests: XCTestCase {

    // MARK: - shortName

    func testShortName_LongName_TruncatesCorrectly() {
        let result = WatchStyleHelper.shortName("Mannheim Hauptbahnhof")
        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThanOrEqual(result.count, "Mannheim Hauptbahnhof".count)
    }

    func testShortName_ShortName_Unchanged() {
        let result = WatchStyleHelper.shortName("Hbf")
        XCTAssertEqual(result, "Hbf")
    }

    func testShortName_Nil_ReturnsEmptyOrPlaceholder() {
        let result = WatchStyleHelper.shortName(nil)
        XCTAssertNotNil(result)
    }

    // MARK: - icon

    func testIcon_Tram_ReturnsTramIcon() {
        let icon = WatchStyleHelper.icon(serviceType: "STRASSENBAHN", serviceName: "3")
        XCTAssertFalse(icon.isEmpty)
    }

    func testIcon_Bus_ReturnsBusIcon() {
        let icon = WatchStyleHelper.icon(serviceType: "BUS", serviceName: "63")
        XCTAssertFalse(icon.isEmpty)
    }

    func testIcon_NilServiceType_ReturnsDefault() {
        let icon = WatchStyleHelper.icon(serviceType: nil, serviceName: nil)
        XCTAssertFalse(icon.isEmpty)
    }
}

final class WatchDepartureTests: XCTestCase {

    private func makeDeparture(id: String = "dep-1",
                               lineName: String = "3",
                               direction: String = "Rheinau",
                               scheduledTime: String = "2026-08-28T10:00:00+02:00") -> WatchDeparture {
        WatchDeparture(
            id: id,
            lineName: lineName,
            direction: direction,
            scheduledTime: scheduledTime,
            estimatedTime: nil,
            serviceType: "STRASSENBAHN",
            delayMinutes: nil
        )
    }

    func testWatchDeparture_Equatable_SameIDAndTime() {
        let dep1 = makeDeparture()
        let dep2 = makeDeparture()
        XCTAssertEqual(dep1, dep2)
    }

    func testWatchDeparture_Equatable_DifferentID() {
        let dep1 = makeDeparture(id: "dep-1")
        let dep2 = makeDeparture(id: "dep-2")
        XCTAssertNotEqual(dep1, dep2)
    }

    func testWatchDeparture_Codable_RoundTrip() throws {
        let dep = WatchDeparture(
            id: "rt-1",
            lineName: "5",
            direction: "Sandhofen",
            scheduledTime: "2026-08-28T12:30:00+02:00",
            estimatedTime: "2026-08-28T12:32:00+02:00",
            serviceType: "STRASSENBAHN",
            delayMinutes: 2
        )
        let data = try JSONEncoder().encode(dep)
        let decoded = try JSONDecoder().decode(WatchDeparture.self, from: data)
        XCTAssertEqual(dep, decoded)
    }

    func testWatchDeparture_WithDelay_IsPreserved() {
        let dep = WatchDeparture(
            id: "delayed-1",
            lineName: "4",
            direction: "Käfertal",
            scheduledTime: "2026-08-28T09:00:00+02:00",
            estimatedTime: "2026-08-28T09:05:00+02:00",
            serviceType: "STRASSENBAHN",
            delayMinutes: 5
        )
        XCTAssertEqual(dep.delayMinutes, 5)
        XCTAssertNotNil(dep.estimatedTime)
    }
}
