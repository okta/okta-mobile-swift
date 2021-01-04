//
//  IDX.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-09.
//

import Foundation

/// The IDXClient class is used to define and initiate an authentication workflow utilizing the Okta Identity Engine. Your app can use this to begin a customizable workflow to authenticate and verify the identity of a user using your application.
///
/// The `IDXClient.Configuration` class is used to communicate which application, defined within Okta, the user is being authenticated with. From this point a workflow is initiated, consisting of a series of authentication "Remediation" steps. At each step, your application can introspect the `IDXClient.Response` object to determine which UI should be presented to your user to guide them through to login.
@objc
public class IDXClient: NSObject, IDXClientAPI {
    @objc(OKTIdentityEngineVersion)
    /// The Okta Identity Engine API version to use.
    public enum Version: Int {
        /// API version 1.0.0
        case v1_0_0
    }
    
    /// Configuration options for an IDXClient.
    @objc(IDXClientConfiguration)
    public class Configuration: NSObject {
        /// The issuer URL.
        public let issuer: String
        
        /// The application's client ID.
        public let clientId: String
        
        /// The application's client secret, if required.
        public let clientSecret: String?
        
        /// The access scopes required by the client.
        public let scopes: [String]
        
        /// The application's redirect URI.
        public let redirectUri: String

        /// Initializes an IDX configuration object.
        /// - Parameters:
        ///   - issuer: The issuer URL.
        ///   - clientId: The application's client ID.
        ///   - clientSecret: The application's client secret, if required.
        ///   - scopes: The application's access scopes.
        ///   - redirectUri: The application's redirect URI.
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

        internal var codeVerifier: String?
    }
    
    /// Configuration used to create the IDX client.
    public let configuration: Configuration
    
    /// Initializes an IDXClient instance with the given configuration values.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The application's client ID.
    ///   - clientSecret: The application's client secret, if required.
    ///   - scopes: The application's access scopes.
    ///   - redirectUri: The application's redirect URI.
    ///   - version: The API version to use, or `latest` if not supplied.
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
    
    /// Initializes an IDX client instance with the given configuration object.
    /// - Parameters:
    ///   - configuration: Configuration object describing the application.
    ///   - version: The API version to use, or `latest` if not supplied.
    ///   - queue: The DispatchQueue to send responses on, defaults to `DispatchQueue.main`.
    public convenience init(configuration: Configuration,
                            version: Version = Version.latest,
                            queue: DispatchQueue = DispatchQueue.main)
    {
        self.init(configuration: configuration,
                  api: version.clientImplementation(with: configuration),
                  queue: queue)
    }

    internal let api: IDXClientAPIImpl
    internal let queue: DispatchQueue
    internal required init(configuration: Configuration,
                           api: IDXClientAPIImpl,
                           queue: DispatchQueue)
    {
        self.configuration = configuration
        self.api = api
        self.queue = queue

        super.init()

        self.api.delegate = self
    }
}
