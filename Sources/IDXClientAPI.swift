//
//  IDXClientAPI.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

public enum IDXClientError: Error {
    case invalidClient
    case stateHandleMissing
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
    func start(completion: @escaping (IDXClient.Response?, Error?) -> Void)
    func cancel(completion: @escaping (Error?) -> Void)
    func proceed(remediation option: IDXClient.Remediation.Option,
                 data: [String : Any]?,
                 completion: @escaping (IDXClient.Response?, Swift.Error?) -> Void)
    func exchangeCode(using successResponse: IDXClient.Remediation.Option,
                      completion: @escaping (IDXClient.Token?, Swift.Error?) -> Void)
}
