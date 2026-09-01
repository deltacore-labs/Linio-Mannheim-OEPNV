//
//  LiveActivityStateTests.swift
//  LinioTests
//
//  Unit Tests für LiveActivityState
//

import XCTest
@testable import Linio

final class LiveActivityStateTests: XCTestCase {
    
    var sut: LiveActivityState!
    
    override func setUp() {
        super.setUp()
        sut = LiveActivityState.shared
        sut.deactivateAllTrips()
    }
    
    override func tearDown() {
        sut.deactivateAllTrips()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - setTripActive Tests
    
    func test_setTripActive_true_makesTripActive() {
        let tripId = "test-trip-123"
        sut.setTripActive(tripId, isActive: true)
        XCTAssertTrue(sut.isTripActive(tripId))
    }
    
    func test_setTripActive_false_makesTripInactive() {
        let tripId = "test-trip-456"
        sut.setTripActive(tripId, isActive: true)
        sut.setTripActive(tripId, isActive: false)
        XCTAssertFalse(sut.isTripActive(tripId))
    }
    
    // MARK: - getAllActiveTrips Tests
    
    func test_getAllActiveTrips_returnsAllActiveTrips() {
        let trip1 = "trip-1"
        let trip2 = "trip-2"
        sut.setTripActive(trip1, isActive: true)
        sut.setTripActive(trip2, isActive: true)
        
        let activeTrips = sut.getAllActiveTrips()
        
        XCTAssertEqual(activeTrips.count, 2)
        XCTAssertTrue(activeTrips.contains(trip1))
        XCTAssertTrue(activeTrips.contains(trip2))
    }
    
    // MARK: - deactivateAllTrips Tests
    
    func test_deactivateAllTrips_removesAllTrips() {
        sut.setTripActive("trip-1", isActive: true)
        sut.setTripActive("trip-2", isActive: true)
        
        sut.deactivateAllTrips()
        
        XCTAssertEqual(sut.getAllActiveTrips().count, 0)
    }
    
    // MARK: - TripPhase Tests
    
    func test_tripPhase_encodesAndDecodes() throws {
        let phases: [TripPhase] = [.beforeDeparture, .duringJourney, .arrived]
        
        for phase in phases {
            let encoded = try JSONEncoder().encode(phase)
            let decoded = try JSONDecoder().decode(TripPhase.self, from: encoded)
            XCTAssertEqual(decoded, phase)
        }
    }
    
    // MARK: - Notification Tests
    
    func test_setTripActive_postsNotification() {
        let expectation = expectation(forNotification: LiveActivityState.activeTripsDidChangeNotification, object: nil)
        
        sut.setTripActive("notification-test-trip", isActive: true)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
