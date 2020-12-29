//
//  IDX.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

#if canImport(Combine)
import Combine
#endif

@objc
public class IDXClient: NSObject, IDXClientAPI {
    @objc(OKTIdentityEngineVersion)
    public enum Version: Int {
        case v1_0_0
    }
    
    @objc(IDXClientConfiguration)
    public class Configuration: NSObject {
        public let issuer: String
        public let clientId: String
        public let clientSecret: String?
        public let scopes: [String]
        public let redirectUri: String
        internal var codeVerifier: String?
        
        public init(issuer: String,
             clientId: String,
             clientSecret: String?,
             scopes: [String],
             redirectUri: String)
        {
            self.issuer = issuer
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.scopes = scopes
            self.redirectUri = redirectUri
            
            super.init()
        }
    }
    
    @objc(IDXCredentials)
    public class Credentials: NSObject {
        public let passcode: String
        public let answer: String
        
        public init(passcode: String, answer: String) {
            self.passcode = passcode
            self.answer = answer
            
            super.init()
        }
    }

    @objc(IDXAuthenticator)
    public class Authenticator: NSObject {
        public let id: String
        public let methodType: String
        public let phoneNumber: String

        public init(id: String, methodType: String, phoneNumber: String) {
            self.id = id
            self.methodType = methodType
            self.phoneNumber = phoneNumber
            
            super.init()
        }
    }

    public let configuration: Configuration
    internal let api: IDXClientAPIImpl
    
    public convenience init(issuer: String,
         clientId: String,
         clientSecret: String? = nil,
         scopes: [String],
         redirectUri: String,
         version: Version = Version.latest)
    {
        self.init(configuration: Configuration(issuer: issuer,
                                               clientId: clientId,
                                               clientSecret: clientSecret,
                                               scopes: scopes,
                                               redirectUri: redirectUri),
                  version: version)
    }
    
    public convenience init(configuration: Configuration,
                            version: Version = Version.latest)
    {
        self.init(configuration: configuration,
                  api: version.clientImplementation(with: configuration))
    }
    

    internal required init(configuration: Configuration,
                           api: IDXClientAPIImpl)
    {
        self.configuration = configuration
        self.api = api

        super.init()

        self.api.delegate = self
    }
    
    public func start(completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        interact { (interactionHandle, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let interactionHandle = interactionHandle else {
                completion(nil, IDXClientError.invalidResponseData)
                return
            }
            
            self.introspect(interactionHandle, completion: completion)
        }
    }
    
    public func proceed(remediation option: Remediation.Option,
                        data: [String : Any]? = nil,
                        completion: @escaping (IDXClient.Response?, Error?) -> Void)
    {
        self.api.proceed(remediation: option, data: data, completion: completion)
    }
}

#if canImport(Combine)
@available(iOS 13.0, *)
extension IDXClient {
    public func interact() -> Future<String, Error>
    {
        return Future<String, Error> { (promise) in
            self.interact { (handle, error) in
                if let error = error {
                    promise(.failure(error))
                } else if let handle = handle {
                    promise(.success(handle))
                } else {
                    promise(.failure(IDXClientError.invalidResponseData))
                }
            }
        }
    }
    
    public func introspect(_ interactionHandle: String) -> Future<IDXClient.Response, Error>
    {
        return Future<IDXClient.Response, Error> { (promise) in
            self.introspect(interactionHandle) { (response, error) in
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
