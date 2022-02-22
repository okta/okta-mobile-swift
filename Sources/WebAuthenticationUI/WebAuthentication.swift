//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

@_exported import AuthFoundation

import Foundation
import OktaOAuth2

#if canImport(UIKit) || canImport(AppKit)

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if os(Linux)
import FoundationNetworking
#endif

public enum WebAuthenticationError: Error {
    case defaultPropertyListNotFound
    case invalidPropertyList(url: URL)
    case cannotParsePropertyList(_ error: Error?)
    case missingConfigurationValues
    case noCompatibleAuthenticationProviders
    case cannotComposeAuthenticationURL
    case authenticationProviderError(_ error: Error)
    case invalidRedirectScheme(_ scheme: String?)
    case userCancelledLogin
    case oauth2(error: OAuth2Error)
    case generic(error: Error)
    case genericError(message: String)
}

/// Authentication coordinator that simplifies signing users in using browser-based OIDC authentication flows.
///
/// This simple class encapsulates the details of managing browser instances across iOS/macOS versions, coordinating with OAuth2 endpoints, and supporting a variety of conveniences when signing users into your application.
///
/// The simplest way to authenticate a user is to use the ``shared`` property to access your default session, and calling ``start(from:)`` to present the browser to the user.
///
/// ```swift
/// let token = try await WebAuthentication.shared.signIn(from: view.window)
/// ```
///
/// To customize the authentication flow, please read more about the underlying OAuth2 client within the OktaOAuth2 library, and how that relates to the ``flow`` property.
///
///  > Important: If your application targets iOS 9.x-10.x, you should add the redirect URI for your client configuration to your app's supported URL schemes.  This is because users on devices older than iOS 11 will be prompted to sign in using `SFSafariViewController`, which does not allow your application to detect the final token redirect.
public class WebAuthentication {
    #if os(macOS)
    public typealias WindowAnchor = NSWindow
    #else
    public typealias WindowAnchor = UIWindow
    #endif
    
    /// Active / default shared instance of the ``WebAuthentication`` session.
    ///
    /// This convenience property exposes either the msot recent WebAuthentication instance, or will construct the default based on client details configured within your app's `Okta.plist` configuration file.
    private(set) public static var shared: WebAuthentication? {
        set {
            _shared = newValue
        }
        get {
            guard let result = _shared else {
                _shared = try? WebAuthentication()
                return _shared
            }
            return result
        }
    }
    
    /// The underlying OAuth2 flow that implements the authentication behavior.
    public let flow: AuthorizationCodeFlow
    
    /// Context information about the current authorization code flow.
    ///
    /// This represents the state and other challenge data necessary to resume the authentication flow.
    public let context: AuthorizationCodeFlow.Context?
    
    /// Indicates whether or not the developer prefers an ephemeral browser session, or if the user's browser state should be shared with the system browser.
    public var ephemeralSession: Bool = false
    
    /// Starts sign-in using the configured client.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - completion: Completion block that will be invoked when authentication finishes.
    public func start(from window: WindowAnchor?, completion: @escaping (Result<Token, WebAuthenticationError>) -> Void) {
        if provider != nil {
            cancel()
        }
        
        let provider = createWebAuthenticationProvider(flow: flow,
                                                       from: window,
                                                       delegate: self)
        self.completionBlock = completion
        self.provider = provider

        provider?.start(context: context)
    }
    
    /// Cancels the authentication session.
    public func cancel() {
        flow.cancel()
        provider?.cancel()
        provider = nil
    }
    
    #if os(iOS)
    /// Attempts to resume sign in when the app is launched from a redirect URI.
    ///
    /// This is a convenience method that can simplify apps that use a UISceneDelegate. Scene-based applications receive URLs when the `UIWindowSceneDelegate.scene(_:openURLContexts:)` method is called; the set of contexts can be supplied to this method, which will filter out only those URLs that match the URL scheme defined in the client configuration. If no matching URLs are found, the call is ignored.
    /// - Parameter URLContexts: Set of `UIOpenURLContext` objects from which to attempt to resume authentication.
    @available(iOS 13.0, *)
    public func resume(with URLContexts: Set<UIOpenURLContext>) throws {
        try URLContexts
            .filter { $0.url.scheme?.lowercased() == flow.callbackScheme?.lowercased() }
            .map(\.url)
            .forEach { try resume(with: $0) }
    }
    #endif
    
    /// Attempts to resume sign in when the app is launched from a redirect URI.
    ///
    /// This method is used when the sign in process continues outside of the application and its embedded authentication browser. When the application is opened using this redirect URI, this method can be used to resume the flow using that URL.
    ///
    /// If the URI does not match the configured URI scheme, this method will thrown an error.
    /// - Parameter url: URL from which to attempt to resume authentication.
    public func resume(with url: URL) throws {
        guard url.scheme?.lowercased() == flow.callbackScheme?.lowercased()
        else {
            throw WebAuthenticationError.invalidRedirectScheme(url.scheme)
        }
        
        try flow.resume(with: url) { _ in
            self.provider = nil
        }
        
        self.provider?.cancel()
    }
    
    /// Initializes a web authentiation session using client credentials defined within the application's `Okta.plist` file.
    public convenience init() throws {
        guard let file = Bundle.main.url(forResource: "Okta", withExtension: "plist") else {
            throw WebAuthenticationError.defaultPropertyListNotFound
        }
        
        try self.init(plist: file)
    }
    
    /// Initializes a web authentication session using client credentials defined within the provided file URL.
    /// - Parameter fileURL: File URL to a `plist` file containing client credentials.
    public convenience init(plist fileURL: URL) throws {
        guard fileURL.isFileURL else {
            throw WebAuthenticationError.invalidPropertyList(url: fileURL)
        }
        
        let plistContent: Any
        do {
            let data = try Data(contentsOf: fileURL)
            plistContent = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw WebAuthenticationError.cannotParsePropertyList(error)
        }
        
        guard let dict = plistContent as? [String: String] else {
            throw WebAuthenticationError.cannotParsePropertyList(nil)
        }
        
        guard let clientId = dict["clientId"],
              !clientId.isEmpty,
              let issuer = dict["issuer"],
              let issuerUrl = URL(string: issuer),
              let scopes = dict["scopes"],
              !scopes.isEmpty,
              let redirectUriString = dict["redirectUri"],
              let redirectUri = URL(string: redirectUriString)
        else {
            throw WebAuthenticationError.missingConfigurationValues
        }
        
        let logoutRedirectUri: URL?
        if let logoutRedirectUriString = dict["logoutRedirectUri"] {
            logoutRedirectUri = URL(string: logoutRedirectUriString)
        } else {
            logoutRedirectUri = nil
        }
        
        let clientSecret = dict["clientSecret"]
        
        // Filter only additional parameters
        let additionalParameters = dict.filter {
            !["clientId", "clientSecret", "issuer", "scopes", "redirectUri", "logoutRedirectUri"].contains($0.key)
        }

        self.init(issuer: issuerUrl,
                  clientId: clientId,
                  clientSecret: clientSecret,
                  scopes: scopes,
                  redirectUri: redirectUri,
                  logoutRedirectUri: logoutRedirectUri,
                  additionalParameters: additionalParameters.isEmpty ? nil : additionalParameters)
    }
    
    /// Initializes a web authentication session using the supplied client credentials.
    /// - Parameters:
    ///   - issuer: The URL for the OAuth2 issuer.
    ///   - clientId: The client's ID.
    ///   - clientSecret: The client's secret, if applicable.
    ///   - scopes: The scopes the client is requesting.
    ///   - responseType: The response type to expect.
    ///   - redirectUri: The redirect URI for the configured client.
    ///   - logoutRedirectUri: The logout URI for the client, if applicable.
    ///   - additionalParameters: Optional parameters to add to the authorization query string.
    public convenience init(issuer: URL,
                            clientId: String,
                            clientSecret: String? = nil,
                            scopes: String,
                            responseType: ResponseType = .code,
                            redirectUri: URL,
                            logoutRedirectUri: URL? = nil,
                            additionalParameters: [String:String]? = nil)
    {
        self.init(issuer: issuer,
                  configuration: .init(clientId: clientId,
                                       clientSecret: clientSecret,
                                       scopes: scopes,
                                       responseType: responseType,
                                       redirectUri: redirectUri,
                                       logoutRedirectUri: logoutRedirectUri,
                                       additionalParameters: additionalParameters))
    }
    
    /// Initializes a web authentication session using the supplied AuthorizationCodeFlow configuration, and optional URL session.
    ///
    /// This constructor can be used when a custom URL session is required.
    /// - Parameters:
    ///   - configuration: Authorization code flow configuration describing the OAuth2 client.
    ///   - session: The URLSession instance to use; defaults to `.shared`.
    public convenience init(issuer: URL,
                            configuration: AuthorizationCodeFlow.Configuration,
                            session: URLSession = URLSession.shared)
    {
        self.init(flow: .init(configuration,
                              client: .init(baseURL: issuer,
                                            session: session)))
    }
    
    func createWebAuthenticationProvider(flow: AuthorizationCodeFlow,
                                         from window: WebAuthentication.WindowAnchor?,
                                         delegate: WebAuthenticationProviderDelegate) -> WebAuthenticationProvider?
    {
        if #available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *) {
            return AuthenticationServicesProvider(flow: flow,
                                                  from: window,
                                                  delegate: delegate)
        }
        
        #if os(iOS)
        if #available(iOS 11.0, *) {
            return SafariServicesProvider(flow: flow,
                                          delegate: delegate)
        }
        
        if #available(iOS 9.0, *) {
            return SafariBrowserProvider(flow: flow,
                                         from: window,
                                         delegate: delegate)
        }
        
        #endif
        
        return nil
    }
    
    /// Initializes a web authentication session using the supplied AuthorizationCodeFlow and optional context.
    /// - Parameters:
    ///   - flow: Authorization code flow instance for this client.
    ///   - context: Optional context to initialize authentication with.
    public init(flow: AuthorizationCodeFlow, context: AuthorizationCodeFlow.Context? = nil) {
        self.flow = flow
        self.context = context
        WebAuthentication.shared = self
    }
    
    // MARK: Internal members
    private static var _shared: WebAuthentication?
    var provider: WebAuthenticationProvider?
    var completionBlock: ((Result<Token, WebAuthenticationError>) -> Void)?
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension WebAuthentication {
    /// Asynchronous convenience method that initiates sign in using the default client configuration, returning a token when successful.
    /// - Parameter window: The window from which the authentication browser should be shown.
    /// - Returns: The token representing the signed-in user.
    public static func signIn(from window: WindowAnchor?) async throws -> Token {
        let client = try shared ?? .init()
        return try await client.start(from: window)
    }
    
    /// Asynchronously initiates authentication from the given window.
    /// - Parameter window: The window from which the authentication browser should be shown.
    /// - Returns: The token representing the signed-in user.
    public func start(from window: WindowAnchor?) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            self.start(from: window) { continuation.resume(with: $0) }
        }
    }
}
#endif
#endif
