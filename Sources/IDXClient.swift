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
public final class IDXClient: NSObject, IDXClientAPI {
    @objc(OKTIdentityEngineVersion)
    /// The Okta Identity Engine API version to use.
    public enum Version: Int {
        /// API version 1.0.0
        case v1_0_0
    }
    
    /// Configuration options for an IDXClient.
    @objc(IDXClientConfiguration)
    public final class Configuration: NSObject {
        /// The issuer URL.
        @objc public let issuer: String
        
        /// The application's client ID.
        @objc public let clientId: String
        
        /// The application's client secret, if required.
        @objc public let clientSecret: String?
        
        /// The access scopes required by the client.
        @objc public let scopes: [String]
        
        /// The application's redirect URI.
        @objc public let redirectUri: String

        /// Initializes an IDX configuration object.
        /// - Parameters:
        ///   - issuer: The issuer URL.
        ///   - clientId: The application's client ID.
        ///   - clientSecret: The application's client secret, if required.
        ///   - scopes: The application's access scopes.
        ///   - redirectUri: The application's redirect URI.
        @objc public init(issuer: String,
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
    
    /// Configuration used to create the IDX client.
    @objc public let configuration: Configuration
    
    /// The current context for the authentication session.
    @objc public internal(set) var context: Context?
    
    /// Initializes an IDX client instance with the given configuration object.
    /// - Parameters:
    ///   - configuration: Configuration object describing the application.
    ///   - context: Context object to use when resuming a session.
    ///   - version: The API version to use, or `latest` if not supplied.
    ///   - queue: The DispatchQueue to send responses on, defaults to `DispatchQueue.main`.
    @objc public convenience init(configuration: Configuration,
                                  context: Context? = nil,
                                  version: Version = Version.latest,
                                  queue: DispatchQueue = DispatchQueue.main)
    {
        self.init(configuration: configuration,
                  context: context,
                  api: version.clientImplementation(with: configuration),
                  queue: queue)
    }

    internal let api: IDXClientAPIImpl
    internal let queue: DispatchQueue
    internal required init(configuration: Configuration,
                           context: Context?,
                           api: IDXClientAPIImpl,
                           queue: DispatchQueue)
    {
        self.configuration = configuration
        self.context = context
        self.api = api
        self.queue = queue

        super.init()

        self.api.delegate = self
        self.api.interactionHandle = context?.interactionHandle
        self.api.codeVerifier = context?.codeVerifier
    }
}
