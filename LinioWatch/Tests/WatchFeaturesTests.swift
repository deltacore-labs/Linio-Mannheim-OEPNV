// WatchFeaturesTests.swift
// Tests für die neuen Apple Watch Features

import XCTest
@testable import LinioWatch

final class WatchFeaturesTests: XCTestCase {
    
    // MARK: - Haptic Manager Tests
    
    @MainActor
    func testHapticManagerSingleton() {
        let manager1 = WatchHapticManager.shared
        let manager2 = WatchHapticManager.shared
        XCTAssertTrue(manager1 === manager2, "HapticManager sollte ein Singleton sein")
    }
    
    @MainActor
    func testHapticManagerInitialState() {
        let manager = WatchHapticManager.shared
        XCTAssertFalse(manager.isMonitoringActive, "Monitoring sollte initial nicht aktiv sein")
        XCTAssertNil(manager.lastHapticEvent, "Kein Event sollte initial gesetzt sein")
    }
    
    @MainActor
    func testHapticEventDescriptions() {
        let events: [(WatchHapticManager.HapticEvent, String)] = [
            (.departureReminder(minutesUntil: 5), "Abfahrt in 5 Min"),
            (.interchangeSoon(nextLine: "5", minutesUntil: 2), "Umstieg auf 5 in 2 Min"),
            (.interchangeNow(nextLine: "6"), "Jetzt umsteigen auf 6"),
            (.arrivalSoon(station: "Hauptbahnhof", minutesUntil: 3), "Ankunft Hauptbahnhof in 3 Min"),
            (.arrived(station: "Bismarckplatz"), "Angekommen: Bismarckplatz")
        ]
        
        for (event, expectedDesc) in events {
            XCTAssertEqual(event.description, expectedDesc, "Event-Beschreibung falsch für \(event)")
        }
    }
    
    // MARK: - Intent Data Provider Tests
    
    func testIntentDataProviderFindTrip() {
        let provider = WatchIntentDataProvider()
        
        // Test mit leeren Daten
        let trip = provider.findTripTo(destination: "Heidelberg")
        // Ohne gespeicherte Daten sollte nil zurückkommen
        XCTAssertNil(trip, "Ohne Daten sollte keine Fahrt gefunden werden")
    }
    
    // MARK: - Complication Entry Tests
    
    func testComplicationEntryPlaceholder() {
        let entry = DepartureEntry.placeholder
        XCTAssertTrue(entry.hasActiveTrip, "Placeholder sollte aktive Fahrt haben")
        XCTAssertNotNil(entry.lineName, "Placeholder sollte Linienname haben")
        XCTAssertNotNil(entry.destination, "Placeholder sollte Ziel haben")
    }
    
    func testComplicationEntryEmpty() {
        let entry = DepartureEntry.empty
        XCTAssertFalse(entry.hasActiveTrip, "Empty sollte keine aktive Fahrt haben")
        XCTAssertNil(entry.lineName, "Empty sollte keinen Liniennamen haben")
    }
    
    // MARK: - Model Tests
    
    func testWidgetTripDataEquatable() {
        let trip1 = WidgetTripData(
            id: "test-1",
            startTime: "2026-08-24T10:00:00Z",
            endTime: "2026-08-24T10:30:00Z",
            interchanges: 0,
            startStation: "Start",
            endStation: "End",
            legs: []
        )
        
        let trip2 = WidgetTripData(
            id: "test-1",
            startTime: "2026-08-24T10:00:00Z",
            endTime: "2026-08-24T10:30:00Z",
            interchanges: 1,  // Unterschiedliche Umstiege
            startStation: "Other Start",
            endStation: "Other End",
            legs: []
        )
        
        let trip3 = WidgetTripData(
            id: "test-2",  // Unterschiedliche ID
            startTime: "2026-08-24T10:00:00Z",
            endTime: "2026-08-24T10:30:00Z",
            interchanges: 0,
            startStation: "Start",
            endStation: "End",
            legs: []
        )
        
        XCTAssertEqual(trip1, trip2, "Trips mit gleicher ID und Zeit sollten gleich sein")
        XCTAssertNotEqual(trip1, trip3, "Trips mit unterschiedlicher ID sollten verschieden sein")
    }
    
    // MARK: - Watch Date Helper Tests
    
    func testWatchDateHelperFormatTime() {
        let result = WatchDateHelper.formatTime("2026-08-24T14:32:00Z")
        // Der genaue Wert hängt von der Zeitzone ab
        XCTAssertFalse(result.isEmpty, "Formatierte Zeit sollte nicht leer sein")
        XCTAssertNotEqual(result, "--:--", "Gültige Zeit sollte formatiert werden")
    }
    
    func testWatchDateHelperParseValidISO() {
        let date1 = WatchDateHelper.parse("2026-08-24T14:32:00Z")
        XCTAssertNotNil(date1, "Gültige ISO-Datum sollte geparst werden")
        
        let date2 = WatchDateHelper.parse("2026-08-24T14:32:00.123Z")
        XCTAssertNotNil(date2, "ISO-Datum mit Millisekunden sollte geparst werden")
    }
    
    func testWatchDateHelperParseInvalidISO() {
        let date = WatchDateHelper.parse("invalid-date")
        XCTAssertNil(date, "Ungültiges Datum sollte nil zurückgeben")
    }
}
