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
    public func start() -> Future<Response, Error> {
        return Future<Response, Error> { (promise) in
            self.start { (response, error) in
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
extension IDXClient.Remediation.Option {
    public func proceed(with dataFromUI: [String:Any] = [:]) -> Future<IDXClient.Response, Error> {
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
}

@available(iOS 13.0, *)
extension IDXClient.Response {
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
}
#endif
