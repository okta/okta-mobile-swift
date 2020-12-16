//
//  IDXClientAPI.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

@objc
public enum IDXClientAPIError: Int, Swift.Error {
    case invalidClient
    case cannotCreateRequest
    case invalidHTTPResponse
    case invalidResponseData
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

    func proceed(remediation option: IDXClient.Remediation.Option, data: [String:Any], completion: @escaping (IDXClient.Response?, Swift.Error?) -> Void)
}
