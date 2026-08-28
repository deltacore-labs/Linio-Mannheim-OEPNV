//
//  DateFormattingHelperTests.swift
//  LinioTests
//
//  Unit Tests für DateFormattingHelper
//

import XCTest
@testable import Linio

final class DateFormattingHelperTests: XCTestCase {
    
    var sut: DateFormattingHelper!
    
    override func setUp() {
        super.setUp()
        sut = DateFormattingHelper.shared
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - ISO8601 Parsing
    
    func testParseISO8601_ValidString_ReturnsDate() {
        // Given
        let isoString = "2026-08-27T14:30:00+02:00"
        
        // When
        let result = sut.parseISO8601(isoString)
        
        // Then
        XCTAssertNotNil(result, "Sollte gültigen ISO8601 String parsen")
    }
    
    func testParseISO8601_InvalidString_ReturnsNil() {
        // Given
        let invalidString = "not-a-date"
        
        // When
        let result = sut.parseISO8601(invalidString)
        
        // Then
        XCTAssertNil(result, "Sollte nil für ungültigen String zurückgeben")
    }
    
    func testParseISO8601_EmptyString_ReturnsNil() {
        // Given
        let emptyString = ""
        
        // When
        let result = sut.parseISO8601(emptyString)
        
        // Then
        XCTAssertNil(result, "Sollte nil für leeren String zurückgeben")
    }
    
    func testParseISO8601_NullString_ReturnsNil() {
        // Given
        let nullString = "null"
        
        // When
        let result = sut.parseISO8601(nullString)
        
        // Then
        XCTAssertNil(result, "Sollte nil für 'null' String zurückgeben")
    }
    
    // MARK: - Time Formatting
    
    func testFormatTime_ValidISO_ReturnsHHMM() {
        // Given
        let isoString = "2026-08-27T14:30:00+02:00"
        
        // When
        let result = sut.formatTime(isoString)
        
        // Then
        XCTAssertEqual(result, "14:30", "Sollte Zeit im HH:mm Format zurückgeben")
    }
    
    func testFormatTime_InvalidString_ReturnsOriginal() {
        // Given
        let invalidString = "invalid"
        
        // When
        let result = sut.formatTime(invalidString)
        
        // Then
        XCTAssertEqual(result, invalidString, "Sollte Original-String für ungültigen Input zurückgeben")
    }
    
    // MARK: - Delay Calculation
    
    func testCalculateDelay_NoDelay_ReturnsNil() {
        // Given
        let scheduled = "2026-08-27T14:30:00+02:00"
        let estimated = "2026-08-27T14:30:00+02:00"
        
        // When
        let result = sut.calculateDelay(timetabled: scheduled, estimated: estimated)
        
        // Then
        // Note: calculateDelay returns nil for delays <= 0
        XCTAssertNil(result, "Sollte nil für keine Verspätung zurückgeben (Implementierung)")
    }
    
    func testCalculateDelay_5MinutesLate_Returns5() {
        // Given
        let scheduled = "2026-08-27T14:30:00+02:00"
        let estimated = "2026-08-27T14:35:00+02:00"
        
        // When
        let result = sut.calculateDelay(timetabled: scheduled, estimated: estimated)
        
        // Then
        XCTAssertEqual(result, 5, "Sollte 5 Minuten Verspätung zurückgeben")
    }
    
    func testDelayValue_Punctual_ReturnsZero() {
        // Given
        let scheduled = "2026-08-27T14:30:00+02:00"
        let estimated = "2026-08-27T14:30:00+02:00"
        
        // When
        let result = sut.delayValue(timetabled: scheduled, estimated: estimated)
        
        // Then
        XCTAssertEqual(result, 0, "Sollte 0 für pünktlich zurückgeben")
    }
    
    func testCalculateDelay_NilEstimated_ReturnsNil() {
        // Given
        let scheduled = "2026-08-27T14:30:00+02:00"
        let estimated: String? = nil
        
        // When
        let result = sut.calculateDelay(timetabled: scheduled, estimated: estimated)
        
        // Then
        XCTAssertNil(result, "Sollte nil für fehlende Echtzeit zurückgeben")
    }
    
    // MARK: - Duration
    
    func testCalculateDuration_15Minutes_ReturnsCorrect() {
        // Given
        let start = "2026-08-27T14:30:00+02:00"
        let end = "2026-08-27T14:45:00+02:00"
        
        // When
        let result = sut.calculateDuration(start: start, end: end)
        
        // Then
        XCTAssertEqual(result, "15 min")
    }
    
    // MARK: - Phase Detection
    
    func testIsBeforeDeparture_FutureTime_ReturnsTrue() {
        // Given
        let futureDate = Date().addingTimeInterval(600)
        let isoString = sut.formatISO8601(futureDate)
        
        // When
        let result = sut.isBeforeDeparture(isoString)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsBeforeDeparture_PastTime_ReturnsFalse() {
        // Given
        let pastDate = Date().addingTimeInterval(-600)
        let isoString = sut.formatISO8601(pastDate)
        
        // When
        let result = sut.isBeforeDeparture(isoString)
        
        // Then
        XCTAssertFalse(result)
    }
}
