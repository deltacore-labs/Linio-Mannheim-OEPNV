//
//  OccupancyLevelTests.swift
//  LinioTests
//
//  Unit Tests für OccupancyLevel Enum
//

import XCTest
@testable import Linio

final class OccupancyLevelTests: XCTestCase {
    
    // MARK: - Roman Numeral Parsing (API Format)
    
    func testInit_RomanI_ReturnsLow() {
        // Given
        let apiValue = "I"
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .low)
    }
    
    func testInit_RomanII_ReturnsMedium() {
        // Given
        let apiValue = "II"
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .medium)
    }
    
    func testInit_RomanIII_ReturnsHigh() {
        // Given
        let apiValue = "III"
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .high)
    }
    
    // MARK: - String Parsing
    
    func testInit_LowString_ReturnsLow() {
        // Given
        let apiValue = "LOW"
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .low)
    }
    
    func testInit_LowercaseString_ReturnsLow() {
        // Given
        let apiValue = "low"
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .low)
    }
    
    func testInit_UnknownString_ReturnsUnknown() {
        // Given
        let apiValue = "SOMETHING_ELSE"
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .unknown)
    }
    
    func testInit_EmptyString_ReturnsUnknown() {
        // Given
        let apiValue = ""
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .unknown)
    }
    
    func testInit_WhitespaceAroundValue_IsTrimmed() {
        // Given
        let apiValue = "  II  "
        
        // When
        let result = OccupancyLevel(from: apiValue)
        
        // Then
        XCTAssertEqual(result, .medium, "Sollte Whitespace trimmen")
    }
    
    // MARK: - Display Properties
    
    func testDisplayText_Low_ReturnsGering() {
        XCTAssertEqual(OccupancyLevel.low.displayText, "Gering")
    }
    
    func testDisplayText_Medium_ReturnsMittel() {
        XCTAssertEqual(OccupancyLevel.medium.displayText, "Mittel")
    }
    
    func testDisplayText_High_ReturnsHoch() {
        XCTAssertEqual(OccupancyLevel.high.displayText, "Hoch")
    }
    
    func testDisplayText_Unknown_ReturnsKeineDaten() {
        XCTAssertEqual(OccupancyLevel.unknown.displayText, "Keine Daten")
    }
    
    // MARK: - Icon Names
    
    func testIconName_Low_ReturnsPerson() {
        XCTAssertEqual(OccupancyLevel.low.iconName, "person")
    }
    
    func testIconName_Medium_ReturnsPerson2() {
        XCTAssertEqual(OccupancyLevel.medium.iconName, "person.2")
    }
    
    func testIconName_High_ReturnsPerson3() {
        XCTAssertEqual(OccupancyLevel.high.iconName, "person.3")
    }
    
    // MARK: - Severity Rank
    
    func testSeverityRank_IsOrdered() {
        XCTAssertLessThan(OccupancyLevel.unknown.severityRank, OccupancyLevel.low.severityRank)
        XCTAssertLessThan(OccupancyLevel.low.severityRank, OccupancyLevel.medium.severityRank)
        XCTAssertLessThan(OccupancyLevel.medium.severityRank, OccupancyLevel.high.severityRank)
    }
    
    // MARK: - Filled Count (für UI-Balken)
    
    func testFilledCount_Unknown_ReturnsZero() {
        XCTAssertEqual(OccupancyLevel.unknown.filledCount, 0)
    }
    
    func testFilledCount_Low_ReturnsOne() {
        XCTAssertEqual(OccupancyLevel.low.filledCount, 1)
    }
    
    func testFilledCount_Medium_ReturnsTwo() {
        XCTAssertEqual(OccupancyLevel.medium.filledCount, 2)
    }
    
    func testFilledCount_High_ReturnsThree() {
        XCTAssertEqual(OccupancyLevel.high.filledCount, 3)
    }
}
