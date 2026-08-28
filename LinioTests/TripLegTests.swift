//
//  TripLegTests.swift
//  LinioTests
//
//  Unit Tests für TripLeg und DetailedTrip
//

import XCTest
@testable import Linio

final class TripLegTests: XCTestCase {
    
    // MARK: - LegType
    
    func testLegType_RawValues_AreCorrect() {
        XCTAssertEqual(LegType.timedLeg.rawValue, "TimedLeg")
        XCTAssertEqual(LegType.continuousLeg.rawValue, "ContinuousLeg")
        XCTAssertEqual(LegType.interchangeLeg.rawValue, "InterchangeLeg")
    }
    
    func testLegType_Codable_EncodesAndDecodes() throws {
        // Given
        let legType = LegType.timedLeg
        
        // When
        let data = try JSONEncoder().encode(legType)
        let decoded = try JSONDecoder().decode(LegType.self, from: data)
        
        // Then
        XCTAssertEqual(legType, decoded)
    }
    
    // MARK: - TripLeg
    
    func testTripLeg_IsTimedLeg_ReturnsTrue() {
        // Given
        let leg = createTimedLeg()
        
        // Then
        XCTAssertTrue(leg.isTimedLeg)
    }
    
    func testTripLeg_ContinuousLeg_IsTimedLegReturnsFalse() {
        // Given
        let leg = TripLeg(
            type: .continuousLeg,
            mode: "WALK",
            boardStopName: nil,
            alightStopName: nil,
            departureTime: nil,
            arrivalTime: nil,
            estimatedDepartureTime: nil,
            estimatedArrivalTime: nil,
            serviceType: nil,
            serviceName: "Fußweg",
            serviceDescription: nil,
            destinationLabel: nil
        )
        
        // Then
        XCTAssertFalse(leg.isTimedLeg)
    }
    
    func testTripLeg_Equatable_IgnoresUUID() {
        // Given
        let leg1 = createTimedLeg()
        let leg2 = createTimedLeg()
        
        // Then
        // Obwohl die UUIDs unterschiedlich sind, sollten sie gleich sein
        XCTAssertEqual(leg1, leg2)
    }
    
    func testTripLeg_Equatable_DifferentValues_AreNotEqual() {
        // Given
        let leg1 = createTimedLeg()
        let leg2 = TripLeg(
            type: .timedLeg,
            mode: nil,
            boardStopName: "Andere Station",
            alightStopName: "Heidelberg Hbf",
            departureTime: "2026-08-27T14:30:00+02:00",
            arrivalTime: "2026-08-27T14:45:00+02:00",
            estimatedDepartureTime: nil,
            estimatedArrivalTime: nil,
            serviceType: "STRASSENBAHN",
            serviceName: "5",
            serviceDescription: nil,
            destinationLabel: "Heidelberg Hbf"
        )
        
        // Then
        XCTAssertNotEqual(leg1, leg2)
    }
    
    func testTripLeg_WithOccupancy_StoresCorrectly() {
        // Given
        let leg = TripLeg(
            type: .timedLeg,
            mode: nil,
            boardStopName: "Mannheim Hbf",
            alightStopName: "Heidelberg Hbf",
            departureTime: "2026-08-27T14:30:00+02:00",
            arrivalTime: "2026-08-27T14:45:00+02:00",
            estimatedDepartureTime: nil,
            estimatedArrivalTime: nil,
            serviceType: "STRASSENBAHN",
            serviceName: "5",
            serviceDescription: nil,
            destinationLabel: "Heidelberg Hbf",
            occupancy: .medium
        )
        
        // Then
        XCTAssertEqual(leg.occupancy, .medium)
    }
    
    // MARK: - DetailedTrip
    
    func testDetailedTrip_StableID_SameInputProducesSameID() {
        // Given
        let legs = [createTimedLeg()]
        
        let trip1 = DetailedTrip(
            startTime: "2026-08-27T14:30:00+02:00",
            endTime: "2026-08-27T14:45:00+02:00",
            interchanges: 0,
            legs: legs
        )
        
        let trip2 = DetailedTrip(
            startTime: "2026-08-27T14:30:00+02:00",
            endTime: "2026-08-27T14:45:00+02:00",
            interchanges: 0,
            legs: legs
        )
        
        // Then
        XCTAssertEqual(trip1.id, trip2.id, "Gleiche Eingaben sollten gleiche IDs erzeugen")
    }
    
    func testDetailedTrip_StableID_DifferentInputProducesDifferentID() {
        // Given
        let legs = [createTimedLeg()]
        
        let trip1 = DetailedTrip(
            startTime: "2026-08-27T14:30:00+02:00",
            endTime: "2026-08-27T14:45:00+02:00",
            interchanges: 0,
            legs: legs
        )
        
        let trip2 = DetailedTrip(
            startTime: "2026-08-27T15:00:00+02:00",
            endTime: "2026-08-27T15:15:00+02:00",
            interchanges: 0,
            legs: legs
        )
        
        // Then
        XCTAssertNotEqual(trip1.id, trip2.id, "Unterschiedliche Eingaben sollten unterschiedliche IDs erzeugen")
    }
    
    func testDetailedTrip_Equatable_ComparesAllFields() {
        // Given
        let legs = [createTimedLeg()]
        
        let trip1 = DetailedTrip(
            startTime: "2026-08-27T14:30:00+02:00",
            endTime: "2026-08-27T14:45:00+02:00",
            interchanges: 0,
            legs: legs
        )
        
        let trip2 = DetailedTrip(
            startTime: "2026-08-27T14:30:00+02:00",
            endTime: "2026-08-27T14:45:00+02:00",
            interchanges: 0,
            legs: legs
        )
        
        // Then
        XCTAssertEqual(trip1, trip2)
    }
    
    // MARK: - Helper
    
    private func createTimedLeg() -> TripLeg {
        TripLeg(
            type: .timedLeg,
            mode: nil,
            boardStopName: "Mannheim Hbf",
            alightStopName: "Heidelberg Hbf",
            departureTime: "2026-08-27T14:30:00+02:00",
            arrivalTime: "2026-08-27T14:45:00+02:00",
            estimatedDepartureTime: nil,
            estimatedArrivalTime: nil,
            serviceType: "STRASSENBAHN",
            serviceName: "5",
            serviceDescription: nil,
            destinationLabel: "Heidelberg Hbf"
        )
    }
}
