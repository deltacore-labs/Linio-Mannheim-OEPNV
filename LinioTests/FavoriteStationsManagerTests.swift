//
//  FavoriteStationsManagerTests.swift
//  LinioTests
//
//  Unit Tests für FavoriteStationsManager
//

import XCTest
@testable import Linio

@MainActor
final class FavoriteStationsManagerTests: XCTestCase {
    
    var sut: FavoriteStationsManager!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = FavoriteStationsManager.shared
        sut.clearAll()
    }
    
    override func tearDown() async throws {
        sut.clearAll()
        sut = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper
    
    private func createStation(globalID: String, name: String) -> Station {
        Station(
            hafasID: "100\(globalID)",
            globalID: globalID,
            longName: name,
            shortName: name,
            latitude: 49.48,
            longitude: 8.46,
            products: ["BUS", "TRAM"]
        )
    }
    
    // MARK: - FavoriteLabel Tests
    
    func test_favoriteLabel_displayNames_areCorrect() {
        XCTAssertEqual(FavoriteLabel.home.displayName, "Zuhause")
        XCTAssertEqual(FavoriteLabel.work.displayName, "Arbeit")
        XCTAssertEqual(FavoriteLabel.university.displayName, "Uni")
    }
    
    func test_favoriteLabel_icons_areCorrect() {
        XCTAssertEqual(FavoriteLabel.home.icon, "house.fill")
        XCTAssertEqual(FavoriteLabel.work.icon, "briefcase.fill")
    }
    
    // MARK: - addFavorite Tests
    
    func test_addFavorite_whenUnderLimit_addsSuccessfully() {
        let station = createStation(globalID: "de:08222:2471", name: "Hauptbahnhof")
        let result = sut.addFavorite(station: station, label: .home)
        
        XCTAssertTrue(result)
        XCTAssertEqual(sut.favorites.count, 1)
    }
    
    func test_addFavorite_whenAlreadyFavorite_returnsFalse() {
        let station = createStation(globalID: "de:08222:2471", name: "Hauptbahnhof")
        _ = sut.addFavorite(station: station, label: .home)
        let result = sut.addFavorite(station: station, label: .work)
        
        XCTAssertFalse(result)
        XCTAssertEqual(sut.favorites.count, 1)
    }
    
    // MARK: - removeFavorite Tests
    
    func test_removeFavorite_byStation_removesCorrectly() {
        let station = createStation(globalID: "de:08222:2471", name: "Hauptbahnhof")
        _ = sut.addFavorite(station: station, label: .home)
        
        sut.removeFavorite(station: station)
        
        XCTAssertEqual(sut.favorites.count, 0)
        XCTAssertFalse(sut.isFavorite(station: station))
    }
    
    // MARK: - isFavorite Tests
    
    func test_isFavorite_whenFavorite_returnsTrue() {
        let station = createStation(globalID: "de:08222:2471", name: "Hauptbahnhof")
        _ = sut.addFavorite(station: station, label: .home)
        XCTAssertTrue(sut.isFavorite(station: station))
    }
    
    func test_isFavorite_whenNotFavorite_returnsFalse() {
        let station = createStation(globalID: "de:08222:2471", name: "Hauptbahnhof")
        XCTAssertFalse(sut.isFavorite(station: station))
    }
    
    // MARK: - canAddMore Tests
    
    func test_canAddMore_whenUnderLimit_returnsTrue() {
        XCTAssertTrue(sut.canAddMore)
    }
}
