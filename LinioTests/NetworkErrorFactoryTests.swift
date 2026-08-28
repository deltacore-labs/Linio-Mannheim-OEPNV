//
//  NetworkErrorFactoryTests.swift
//  LinioTests
//
//  Erweiterte Factory-Tests für NetworkError (HTTP-Codes, URLError-Varianten, Error-Upcast)
//

import XCTest
@testable import Linio

final class NetworkErrorFactoryTests: XCTestCase {

    // MARK: - from(httpStatusCode:)

    func testHttpStatusCode_403_ReturnsForbidden() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 403), .forbidden)
    }

    func testHttpStatusCode_404_ReturnsNotFound() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 404), .notFound)
    }

    func testHttpStatusCode_503_ReturnsServerError() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 503), .serverError)
    }

    func testHttpStatusCode_429_ReturnsHttpError() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 429), .httpError(code: 429))
    }

    func testHttpStatusCode_299_ReturnsNil() {
        XCTAssertNil(NetworkError.from(httpStatusCode: 299))
    }

    func testHttpStatusCode_204_ReturnsNil() {
        XCTAssertNil(NetworkError.from(httpStatusCode: 204))
    }

    func testHttpStatusCode_400_ReturnsHttpError() {
        XCTAssertEqual(NetworkError.from(httpStatusCode: 400), .httpError(code: 400))
    }

    // MARK: - from(_ urlError:)

    func testFromURLError_NetworkLost_ReturnsNoInternet() {
        let urlError = URLError(.networkConnectionLost)
        XCTAssertEqual(NetworkError.from(urlError), .noInternet)
    }

    func testFromURLError_CannotConnectToHost_ReturnsServerUnreachable() {
        let urlError = URLError(.cannotConnectToHost)
        XCTAssertEqual(NetworkError.from(urlError), .serverUnreachable)
    }

    func testFromURLError_CannotFindHost_ReturnsServerUnreachable() {
        let urlError = URLError(.cannotFindHost)
        XCTAssertEqual(NetworkError.from(urlError), .serverUnreachable)
    }

    func testFromURLError_Unknown_ReturnsUnknown() {
        let urlError = URLError(.badServerResponse)
        if case .unknown = NetworkError.from(urlError) { } else {
            XCTFail("Expected .unknown for unhandled URLError code")
        }
    }

    // MARK: - from(_ error: Error)

    func testFromError_NetworkErrorPassthrough() {
        let original = NetworkError.forbidden
        XCTAssertEqual(NetworkError.from(original), .forbidden)
    }

    func testFromError_URLError_Converts() {
        let urlError = URLError(.timedOut)
        XCTAssertEqual(NetworkError.from(urlError as Error), .timeout)
    }

    func testFromError_GenericError_ReturnsUnknown() {
        struct SomeError: Error { var localizedDescription: String { "boom" } }
        if case .unknown(let msg) = NetworkError.from(SomeError()) {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected .unknown for generic error")
        }
    }

    // MARK: - isRetryable

    func testUnauthorized_IsRetryable() {
        XCTAssertTrue(NetworkError.unauthorized.isRetryable)
    }

    func testDecodingFailed_IsNotRetryable() {
        XCTAssertFalse(NetworkError.decodingFailed(reason: "type mismatch").isRetryable)
    }

    func testGraphQLError_IsNotRetryable() {
        XCTAssertFalse(NetworkError.graphQLError(message: "not found").isRetryable)
    }

    // MARK: - shortDescription completeness

    func testAllCasesHaveNonEmptyShortDescription() {
        let cases: [NetworkError] = [
            .noInternet, .timeout, .serverUnreachable,
            .unauthorized, .forbidden, .notFound, .serverError,
            .httpError(code: 418),
            .invalidResponse, .decodingFailed(reason: "x"), .graphQLError(message: "y"),
            .noData, .tokenExpired, .authenticationFailed, .unknown(message: "z")
        ]
        for error in cases {
            XCTAssertFalse(error.shortDescription.isEmpty, "\(error) has empty shortDescription")
        }
    }
}
