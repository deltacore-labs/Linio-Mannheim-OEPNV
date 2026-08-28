//
//  NetworkErrorFactory.swift
//  Linio
//
//  Factory-Methoden für NetworkError.
//

import Foundation

extension NetworkError {
    
    /// Erstellt NetworkError aus URLError
    static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternet
        case .timedOut:
            return .timeout
        case .cannotConnectToHost, .cannotFindHost:
            return .serverUnreachable
        default:
            return .unknown(message: urlError.localizedDescription)
        }
    }
    
    /// Erstellt NetworkError aus HTTP-Statuscode
    static func from(httpStatusCode: Int) -> NetworkError? {
        switch httpStatusCode {
        case 200...299:
            return nil
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 500...599:
            return .serverError
        default:
            return .httpError(code: httpStatusCode)
        }
    }
    
    /// Erstellt NetworkError aus beliebigem Error
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        if let urlError = error as? URLError {
            return from(urlError)
        }
        if let graphQLError = error as? GraphQLError {
            return .graphQLError(message: graphQLError.message)
        }
        return .unknown(message: error.localizedDescription)
    }
}
