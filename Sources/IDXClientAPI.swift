//
//  IDXClientAPI.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

/// Errors reported from IDXClient
public enum IDXClientError: Error {
    case invalidClient
    case cannotCreateRequest
    case invalidHTTPResponse
    case invalidResponseData
    case invalidRequestData
    case serverError(message: String, localizationKey: String, type: String)
    case internalError(message: String)
    case invalidParameter(name: String)
    case invalidParameterValue(name: String, type: String)
    case parameterImmutable(name: String)
    case missingRequiredParameter(name: String)
    case unknownRemediationOption(name: String)
    case successResponseMissing
}

@objc
public protocol IDXClientAPI {
    /// Starts the authentication workflow.
    /// - Parameters:
    ///   - completion: Invoked when a response, or error, is received.
    ///   - response: The response describing the next steps available in this workflow.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    func start(completion: @escaping (_ response: IDXClient.Response?, _ error: Error?) -> Void)
    
    /// Indicates whether or not the current stage in the workflow can be cancelled.
    var canCancel: Bool { get }
    
    /// Cancels the current workflow.
    /// - Parameters:
    ///   - completion: Invoked when the operation is cancelled.
    ///   - response: The response describing the new workflow next steps, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    func cancel(completion: @escaping (_ response: IDXClient.Response?, _ error: Error?) -> Void)
    
    /// Proceeds to the given remediation option.
    /// - Parameters:
    ///   - option: Remediation option to proceed to.
    ///   - data: Optional data to supply to the remediation step.
    ///   - completion: Invoked when a response, or error, is received.
    ///   - response: The response describing the next steps available in this workflow.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    func proceed(remediation option: IDXClient.Remediation.Option,
                 data: [String : Any]?,
                 completion: @escaping (_ response: IDXClient.Response?, _ error: Swift.Error?) -> Void)
    
    /// Exchanges the successful remediation response with a token.
    /// - Parameters:
    ///   - successResponse: Successful remediation option to exchange.
    ///   - completion: Completion handler invoked when a token, or error, is received.
    ///   - token: The token that was exchanged, or `nil` if an error occurred.
    ///   - error: Describes the error that occurred, or `nil` if successful.
    func exchangeCode(using successResponse: IDXClient.Remediation.Option,
                      completion: @escaping (_ token: IDXClient.Token?, _ error: Swift.Error?) -> Void)
}
