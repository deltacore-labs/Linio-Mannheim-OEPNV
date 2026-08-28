//
//  StationModelTests.swift
//  LinioTests
//
//  Unit Tests für Station Model und StationQuay
//

import XCTest
import CoreLocation
@testable import Linio

final class StationModelTests: XCTestCase {
    
    // MARK: - Station
    
    func testStation_ID_EqualsGlobalID() {
        // Given
        let station = Station(
            hafasID: "2417",
            globalID: "de:08222:2417",
            longName: "Heidelberg Hauptbahnhof",
            latitude: 49.4034,
            longitude: 8.6755
        )
        
        // Then
        XCTAssertEqual(station.id, station.globalID)
    }
    
    func testStation_Equatable_SameValues_AreEqual() {
        // Given
        let station1 = Station(
            hafasID: "2417",
            globalID: "de:08222:2417",
            longName: "Heidelberg Hauptbahnhof",
            latitude: 49.4034,
            longitude: 8.6755
        )
        
        let station2 = Station(
            hafasID: "2417",
            globalID: "de:08222:2417",
            longName: "Heidelberg Hauptbahnhof",
            latitude: 49.4034,
            longitude: 8.6755
        )
        
        // Then
        XCTAssertEqual(station1, station2)
    }
    
    func testStation_Codable_EncodesAndDecodes() throws {
        // Given
        let station = Station(
            hafasID: "2417",
            globalID: "de:08222:2417",
            longName: "Heidelberg Hauptbahnhof",
            latitude: 49.4034,
            longitude: 8.6755
        )
        
        // When
        let data = try JSONEncoder().encode(station)
        let decoded = try JSONDecoder().decode(Station.self, from: data)
        
        // Then
        XCTAssertEqual(station, decoded)
    }
    
    func testStation_WithNilCoordinates_StillWorks() {
        // Given
        let station = Station(
            hafasID: "1234",
            globalID: "de:08222:1234",
            longName: "Test Station",
            latitude: nil,
            longitude: nil
        )
        
        // Then
        XCTAssertNil(station.latitude)
        XCTAssertNil(station.longitude)
        XCTAssertEqual(station.longName, "Test Station")
    }
    
    // MARK: - StationQuay
    
    func testQuayText_ValidRef_ReturnsSteig() {
        // Given
        let ref = "de:08222:2417:1:A"
        
        // When
        let result = StationQuay.quayText(fromRef: ref)
        
        // Then
        XCTAssertEqual(result, "Steig A")
    }
    
    func testQuayText_NumericSteig_ReturnsSteig() {
        // Given
        let ref = "de:08222:2417:1:12"
        
        // When
        let result = StationQuay.quayText(fromRef: ref)
        
        // Then
        XCTAssertEqual(result, "Steig 12")
    }
    
    func testQuayText_InvalidRef_ReturnsNil() {
        // Given
        let ref = "invalid"
        
        // When
        let result = StationQuay.quayText(fromRef: ref)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testQuayText_ZeroSteig_ReturnsNil() {
        // Given
        let ref = "de:08222:2417:1:0"
        
        // When
        let result = StationQuay.quayText(fromRef: ref)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testQuayText_NullSteig_ReturnsNil() {
        // Given
        let ref = "de:08222:2417:1:null"
        
        // When
        let result = StationQuay.quayText(fromRef: ref)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testLetter_FromName_ExtractsLastPart() {
        // Given
        let name = "Steig A"
        
        // When
        let result = StationQuay.letter(fromName: name)
        
        // Then
        XCTAssertEqual(result, "A")
    }
    
    func testLetter_SingleWord_ReturnsFirstChar() {
        // Given
        let name = "A"
        
        // When
        let result = StationQuay.letter(fromName: name)
        
        // Then
        XCTAssertEqual(result, "A")
    }
    
    // MARK: - Bounding Region
    
    func testBoundingRegion_MultipleQuays_CalculatesCorrectCenter() {
        // Given
        let quays = [
            StationQuay(id: "1", name: "Steig A", letter: "A",
                       coordinate: CLLocationCoordinate2D(latitude: 49.40, longitude: 8.67)),
            StationQuay(id: "2", name: "Steig B", letter: "B",
                       coordinate: CLLocationCoordinate2D(latitude: 49.42, longitude: 8.69))
        ]
        
        // When
        let region = StationQuay.boundingRegion(for: quays)
        
        // Then
        XCTAssertEqual(region.center.latitude, 49.41, accuracy: 0.001)
        XCTAssertEqual(region.center.longitude, 8.68, accuracy: 0.001)
    }
    
    func testBoundingRegion_EmptyQuays_ReturnsDefaultRegion() {
        // Given
        let quays: [StationQuay] = []
        
        // When
        let region = StationQuay.boundingRegion(for: quays)
        
        // Then
        // Default ist Mannheim-Bereich
        XCTAssertEqual(region.center.latitude, 49.48, accuracy: 0.01)
        XCTAssertEqual(region.center.longitude, 8.47, accuracy: 0.01)
    }
}
