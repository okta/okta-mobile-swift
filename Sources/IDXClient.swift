//
//  IDX.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

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
}
