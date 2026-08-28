//
//  AccessibilityHelpersTests.swift
//  LinioTests
//
//  Unit Tests für AccessibilityHelpers
//

import XCTest
@testable import Linio

final class AccessibilityHelpersTests: XCTestCase {
    
    // MARK: - TripAccessibilityHelper Tests
    
    func testDelayDescription_Zero_ReturnsPunctual() {
        let result = TripAccessibilityHelper.delayDescription(minutes: 0)
        XCTAssertEqual(result, "Pünktlich")
    }
    
    func testDelayDescription_Negative_ReturnsPunctual() {
        let result = TripAccessibilityHelper.delayDescription(minutes: -2)
        XCTAssertEqual(result, "Pünktlich")
    }
    
    func testDelayDescription_One_ReturnsSingular() {
        let result = TripAccessibilityHelper.delayDescription(minutes: 1)
        XCTAssertEqual(result, "1 Minute Verspätung")
    }
    
    func testDelayDescription_Multiple_ReturnsPlural() {
        let result = TripAccessibilityHelper.delayDescription(minutes: 5)
        XCTAssertEqual(result, "5 Minuten Verspätung")
    }
    
    // MARK: - OccupancyDescription Tests
    
    func testOccupancyDescription_Low() {
        let result = TripAccessibilityHelper.occupancyDescription(.low)
        XCTAssertTrue(result.contains("Gering"))
    }
    
    func testOccupancyDescription_Medium() {
        let result = TripAccessibilityHelper.occupancyDescription(.medium)
        XCTAssertTrue(result.contains("Mittler"))
    }
    
    func testOccupancyDescription_High() {
        let result = TripAccessibilityHelper.occupancyDescription(.high)
        XCTAssertTrue(result.contains("Hoh"))
    }
    
    func testOccupancyDescription_Unknown() {
        let result = TripAccessibilityHelper.occupancyDescription(.unknown)
        XCTAssertTrue(result.contains("unbekannt"))
    }
    
    // MARK: - DepartureAccessibilityHelper Tests
    
    func testDepartureLabel_ContainsLineName() {
        let label = DepartureAccessibilityHelper.label(
            lineName: "5",
            destination: "Käfertal",
            departureTime: "2026-08-27T14:30:00+02:00",
            delayMinutes: nil,
            platform: nil
        )
        
        XCTAssertTrue(label.contains("Linie 5"))
        XCTAssertTrue(label.contains("Käfertal"))
    }
    
    func testDepartureLabel_ContainsDelay() {
        let label = DepartureAccessibilityHelper.label(
            lineName: "5",
            destination: "Käfertal",
            departureTime: "2026-08-27T14:30:00+02:00",
            delayMinutes: 3,
            platform: nil
        )
        
        XCTAssertTrue(label.contains("Verspätung"))
    }
    
    func testDepartureLabel_ContainsPlatform() {
        let label = DepartureAccessibilityHelper.label(
            lineName: "5",
            destination: "Käfertal",
            departureTime: "2026-08-27T14:30:00+02:00",
            delayMinutes: nil,
            platform: "A"
        )
        
        XCTAssertTrue(label.contains("Steig A"))
    }
    
    func testDepartureLabel_PunctualWhenZeroDelay() {
        let label = DepartureAccessibilityHelper.label(
            lineName: "5",
            destination: "Käfertal",
            departureTime: "2026-08-27T14:30:00+02:00",
            delayMinutes: 0,
            platform: nil
        )
        
        XCTAssertTrue(label.contains("Pünktlich"))
    }
    
    // MARK: - RelativeTimeLabel Tests
    
    func testRelativeTimeLabel_PastTime_ReturnsAlreadyDeparted() {
        let pastTime = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300))
        let result = DepartureAccessibilityHelper.relativeTimeLabel(departureTime: pastTime)
        XCTAssertEqual(result, "Bereits abgefahren")
    }
    
    func testRelativeTimeLabel_Now_ReturnsDepartsNow() {
        let now = ISO8601DateFormatter().string(from: Date().addingTimeInterval(10))
        let result = DepartureAccessibilityHelper.relativeTimeLabel(departureTime: now)
        // Could be "Fährt jetzt" or "In 1 Minute" depending on exact timing
        XCTAssertTrue(result.contains("jetzt") || result.contains("1 Minute"))
    }
    
    func testRelativeTimeLabel_FutureMinutes_ReturnsInMinutes() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(600)) // 10 min
        let result = DepartureAccessibilityHelper.relativeTimeLabel(departureTime: future)
        XCTAssertTrue(result.contains("In") && result.contains("Minuten"))
    }
}
