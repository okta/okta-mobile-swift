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
    case invalidParameter(name: String)
    case invalidParameterValue(name: String, type: String)
    case parameterImmutable(name: String)
    case missingRequiredParameter(name: String)
    case unknownRemediationOption(name: String)
}

@objc
public protocol IDXClientAPI {
    func interact(completion: @escaping(String?, Error?) -> Void)
    func introspect(_ interactionHandle: String,
                    completion: @escaping (IDXClient.Response?, Error?) -> Void)
    func identify(identifier: String,
                  credentials: IDXClient.Credentials,
                  rememberMe: Bool,
                  completion: @escaping (IDXClient.Response?, Error?) -> Void)
    func enroll(authenticator: IDXClient.Authenticator,
                completion: @escaping (IDXClient.Response?, Error?) -> Void)
    func challenge(authenticator: IDXClient.Authenticator,
                   completion: @escaping (IDXClient.Response?, Error?) -> Void)
    func answerChallenge(credentials: IDXClient.Credentials,
                         completion: @escaping (IDXClient.Response?, Error?) -> Void)
    func cancel(completion: @escaping (Error?) -> Void)
    func token(url: String,
               grantType: String,
               interactionCode: String,
               completion: @escaping(IDXClient.Token?, Error?) -> Void)

    func proceed(remediation option: IDXClient.Remediation.Option,
                 data: [String : Any]?,
                 completion: @escaping (IDXClient.Response?, Swift.Error?) -> Void)
}
