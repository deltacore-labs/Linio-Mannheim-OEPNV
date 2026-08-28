//
//  NetworkErrorTests.swift
//  LinioTests
//
//  Unit Tests für NetworkError
//

import XCTest
@testable import Linio

final class NetworkErrorTests: XCTestCase {
    
    // MARK: - Error Descriptions
    
    func testNoInternet_HasCorrectDescription() {
        let error = NetworkError.noInternet
        XCTAssertEqual(error.errorDescription, "Keine Internetverbindung")
    }
    
    func testTimeout_HasCorrectDescription() {
        let error = NetworkError.timeout
        XCTAssertEqual(error.errorDescription, "Zeitüberschreitung")
    }
    
    func testGraphQLError_PreservesMessage() {
        let message = "Station nicht gefunden"
        let error = NetworkError.graphQLError(message: message)
        XCTAssertEqual(error.errorDescription, message)
    }
    
    // MARK: - Short Descriptions
    
    func testNoInternet_ShortDescription() {
        XCTAssertEqual(NetworkError.noInternet.shortDescription, "Keine Verbindung")
    }
    
    func testServerError_ShortDescription() {
        XCTAssertEqual(NetworkError.serverError.shortDescription, "Serverfehler")
    }
    
    // MARK: - Icon Names
    
    func testNoInternet_IconName() {
        XCTAssertEqual(NetworkError.noInternet.iconName, "wifi.slash")
    }
    
    func testServerError_IconName() {
        XCTAssertEqual(NetworkError.serverError.iconName, "server.rack")
    }
    
    // MARK: - Retryable
    
    func testNoInternet_IsRetryable() {
        XCTAssertTrue(NetworkError.noInternet.isRetryable)
    }
    
    func testTimeout_IsRetryable() {
        XCTAssertTrue(NetworkError.timeout.isRetryable)
    }
    
    func testForbidden_IsNotRetryable() {
        XCTAssertFalse(NetworkError.forbidden.isRetryable)
    }
    
    // MARK: - Factory: from URLError
    
    func testFromURLError_NotConnected_ReturnsNoInternet() {
        let urlError = URLError(.notConnectedToInternet)
        XCTAssertEqual(NetworkError.from(urlError), .noInternet)
    }
    
    func testFromURLError_TimedOut_ReturnsTimeout() {
        let urlError = URLError(.timedOut)
        XCTAssertEqual(NetworkError.from(urlError), .timeout)
    }
    
    // MARK: - Factory: from HTTP Status Code
    
    func testFromHttpStatusCode_200_ReturnsNil() {
        XCTAssertNil(NetworkError.from(httpStatusCode: 200))
    }
    
    func testFromHttpStatusCode_401_ReturnsUnauthorized() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 401), .unauthorized)
    }
    
    func testFromHttpStatusCode_500_ReturnsServerError() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 500), .serverError)
    }
    
    // MARK: - Equatable
    
    func testEquatable_SameError_AreEqual() {
        XCTAssertEqual(NetworkError.noInternet, NetworkError.noInternet)
    }
    
    func testEquatable_DifferentErrors_AreNotEqual() {
        XCTAssertNotEqual(NetworkError.noInternet, NetworkError.timeout)
    }
}
