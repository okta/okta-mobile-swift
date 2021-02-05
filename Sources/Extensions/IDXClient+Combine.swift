//
//  IDXClient+Combine.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-31.
//

import Foundation

#if canImport(Combine)
import Combine

@available(iOS 13.0, *)
extension IDXClient {
    /// Starts the authentication workflow, returning a Future.
    public func start() -> AnyPublisher<IDXClient.Response, Error> {
        return Future<IDXClient.Response, Error> { (promise) in
            self.start { (response, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let response = response {
                    promise(.success(response))
                } else {
                    promise(.failure(IDXClientError.invalidResponseData))
                }
            }
        }.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension IDXClient.Remediation.Option {
    /// Proceeds to the given remediation option, returning a Future.
    /// - Parameters:
    ///   - option: Remediation option to proceed to.
    ///   - data: Optional data to supply to the remediation step.
    public func proceed(_ dataFromUI: [String:Any] = [:]) -> Future<IDXClient.Response, Error> {
        return Future<IDXClient.Response, Error> { (promise) in
            self.proceed(with: dataFromUI) { (response, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let response = response {
                    promise(.success(response))
                } else {
                    promise(.failure(IDXClientError.invalidResponseData))
                }
            }
        }
    }

    public func proceed(_ parameters: IDXClient.Remediation.Parameters) -> Future<IDXClient.Response, Error> {
        return Future<IDXClient.Response, Error> { (promise) in
            self.proceed(with: parameters) { (response, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let response = response {
                    promise(.success(response))
                } else {
                    promise(.failure(IDXClientError.invalidResponseData))
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension IDXClient.Response {
    /// Exchanges the successful remediation response with a token, returning a Future.
    public func exchangeCode() -> Future<IDXClient.Token, Error> {
        return Future<IDXClient.Token, Error> { (promise) in
            self.exchangeCode() { (token, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let token = token {
                    promise(.success(token))
                } else {
                    promise(.failure(IDXClientError.invalidResponseData))
                }
            }
        }
    }

    /// Requests to cancel a remediation step, returning a Future.
    public func cancel() -> Future<IDXClient.Response, Error> {
        return Future<IDXClient.Response, Error> { (promise) in
            self.cancel() { (response, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let response = response {
                    promise(.success(response))
                } else {
                    promise(.failure(IDXClientError.invalidResponseData))
                }
            }
        }
    }
}
#endif
