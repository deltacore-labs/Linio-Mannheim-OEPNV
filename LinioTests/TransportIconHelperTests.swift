//
//  TransportIconHelperTests.swift
//  LinioTests
//
//  Unit Tests für TransportIconHelper
//

import XCTest
import SwiftUI
@testable import Linio

final class TransportIconHelperTests: XCTestCase {
    
    // MARK: - Line Type Detection
    
    func testIsSBahnLine_S1_ReturnsTrue() {
        XCTAssertTrue(TransportIconHelper.isSBahnLine(serviceType: nil, serviceName: "S1"))
    }
    
    func testIsSBahnLine_S12_ReturnsTrue() {
        XCTAssertTrue(TransportIconHelper.isSBahnLine(serviceType: nil, serviceName: "S12"))
    }
    
    func testIsSBahnLine_RegularBus_ReturnsFalse() {
        XCTAssertFalse(TransportIconHelper.isSBahnLine(serviceType: "BUS", serviceName: "64"))
    }
    
    func testIsRegionalLine_RB_ReturnsTrue() {
        XCTAssertTrue(TransportIconHelper.isRegionalLine(serviceType: nil, serviceName: "RB 10"))
    }
    
    func testIsRegionalLine_RE_ReturnsTrue() {
        XCTAssertTrue(TransportIconHelper.isRegionalLine(serviceType: nil, serviceName: "RE 5"))
    }
    
    func testIsLongDistanceLine_ICE_ReturnsTrue() {
        XCTAssertTrue(TransportIconHelper.isLongDistanceLine(serviceType: nil, serviceName: "ICE 123"))
    }
    
    func testIsLongDistanceLine_IC_ReturnsTrue() {
        XCTAssertTrue(TransportIconHelper.isLongDistanceLine(serviceType: nil, serviceName: "IC 456"))
    }
    
    func testIsLongDistanceLine_RegularTram_ReturnsFalse() {
        XCTAssertFalse(TransportIconHelper.isLongDistanceLine(serviceType: "STRASSENBAHN", serviceName: "5"))
    }
    
    // MARK: - Transport Icons
    
    func testGetTransportIcon_SBahn_ReturnsSCircle() {
        let icon = TransportIconHelper.getTransportIcon(for: nil, serviceName: "S5")
        XCTAssertEqual(icon, "s.circle.fill")
    }
    
    func testGetTransportIcon_LongDistance_ReturnsTrain() {
        let icon = TransportIconHelper.getTransportIcon(for: nil, serviceName: "ICE 123")
        XCTAssertEqual(icon, "train.side.front.car")
    }
    
    func testGetTransportIcon_Regional_ReturnsTram() {
        let icon = TransportIconHelper.getTransportIcon(for: nil, serviceName: "RE 5")
        XCTAssertEqual(icon, "tram.fill")
    }
    
    func testGetTransportIcon_Tram_ReturnsLightrail() {
        let icon = TransportIconHelper.getTransportIcon(for: "STRASSENBAHN", serviceName: "5")
        XCTAssertEqual(icon, "lightrail.fill")
    }
    
    func testGetTransportIcon_Bus_ReturnsBus() {
        let icon = TransportIconHelper.getTransportIcon(for: "BUS", serviceName: "64")
        XCTAssertEqual(icon, "bus.fill")
    }
    
    func testGetTransportIcon_Unknown_ReturnsQuestionmark() {
        let icon = TransportIconHelper.getTransportIcon(for: nil, serviceName: nil)
        XCTAssertEqual(icon, "questionmark")
    }
    
    // MARK: - Short Line Name
    
    func testGetShortLineName_WithRNVPrefix_RemovesIt() {
        let result = TransportIconHelper.getShortLineName(from: "RNV 5")
        XCTAssertEqual(result, "5")
    }
    
    func testGetShortLineName_WithLiniePrefix_RemovesIt() {
        let result = TransportIconHelper.getShortLineName(from: "Linie 3")
        XCTAssertEqual(result, "3")
    }
    
    func testGetShortLineName_WithDirectionSuffix_RemovesIt() {
        let result = TransportIconHelper.getShortLineName(from: "3-3")
        XCTAssertEqual(result, "3")
    }
    
    func testGetShortLineName_PlainNumber_ReturnsAsIs() {
        let result = TransportIconHelper.getShortLineName(from: "64")
        XCTAssertEqual(result, "64")
    }
    
    func testGetShortLineName_Nil_ReturnsQuestionmark() {
        let result = TransportIconHelper.getShortLineName(from: nil)
        XCTAssertEqual(result, "?")
    }
    
    // MARK: - Transport Colors
    
    func testGetTransportColor_SBahn_ReturnsGreen() {
        let color = TransportIconHelper.getTransportColor(for: nil, serviceName: "S5")
        // S-Bahn Grün: #00975f
        XCTAssertNotNil(color)
    }
    
    func testGetTransportColor_Bus_ReturnsBlue() {
        let color = TransportIconHelper.getTransportColor(for: "BUS", serviceName: "64")
        // Bus Blau: #4a96d1
        XCTAssertNotNil(color)
    }
}
