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
import OAuth2Auth

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum BrowserSigninError: Error {
    case noCompatibleAuthenticationProviders
    case noSignOutFlowProvided
    case cannotStartBrowserSession
    case cannotComposeAuthenticationURL
    case authenticationProvider(error: any Error)
    case noAuthenticatorProviderResponse
    case serverError(_ error: OAuth2ServerError)
    case invalidRedirectScheme(_ scheme: String?)
    case userCancelledLogin(_ reason: String? = nil)
    case missingIdToken
    case oauth2(error: OAuth2Error)
    case generic(error: any Error)
    case genericError(message: String)
}

/// Authentication coordinator that simplifies signing users in using browser-based OIDC authentication flows.
///
/// This simple class encapsulates the details of managing browser instances across iOS/macOS versions, coordinating with OAuth2 endpoints, and supporting a variety of conveniences when signing users into your application.
///
/// The simplest way to authenticate a user is to use the ``shared`` property to access your default session, and calling ``signIn(from:context:)`` to present the browser to the user.
///
/// ```swift
/// let token = try await BrowserSignin.shared?.signIn(from: view.window)
/// ```
///
/// To customize the authentication flow, please read more about the underlying OAuth2 client within the OAuth2Auth library, and how that relates to the ``signInFlow`` or ``signOutFlow`` properties.
///
///  ## Redirect URI Support
///
///  This library supports both custom URIs and HTTPS redirect URLs on supporting platforms and iOS versions. This requires that your application is configured to use associated domains, with the application's identifier included in the associated domain's `webcredentials` list.
///
///  > Note: The use of HTTPS addresses within the redirect callback URI is limited by the availability of support within ASWebAuthenticationSession, which currently requires a minimum of iOS 17.4, macOS 14.4, watchOS 10.4, tvOS 17.4, or visionOS 1.1.
@MainActor
public final class BrowserSignin {
    #if os(macOS)
    public typealias WindowAnchor = NSWindow
    #elseif os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
    public typealias WindowAnchor = UIWindow
    #else
    public typealias WindowAnchor = Void
    #endif
    
    /// Defines the options used to control the behavior of the browser and its presentation.
    public struct Option: Sendable, OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        #if canImport(AuthenticationServices)
        /// Requests that the browser utilizes an ephemeral session, which does not persist cookies or other browser storage between launches.
        public static let ephemeralSession = Option(rawValue: 1 << 0)
        #endif
    }

    /// Active / default shared instance of the ``BrowserSignin`` session.
    ///
    /// This convenience property can be used in one of two ways:
    ///
    /// 1. Access a shared instance using the settings configured within a file named `Okta.plist`
    /// 2. Programmatically create an instance that can be shared across your application.
    ///
    /// For more information on how to configure your client, see <doc:ConfiguringYourClient> for more details.
    public private(set) static var shared: BrowserSignin? {
        set {
            _shared = newValue
        }
        get {
            guard let result = _shared else {
                _shared = try? BrowserSignin()
                return _shared
            }
            return result
        }
    }

    /// The underlying OAuth2 flow that implements the authentication behavior.
    nonisolated public let signInFlow: AuthorizationCodeFlow
    
    /// The underlying OAuth2 flow that implements the session logout behaviour.
    nonisolated public let signOutFlow: SessionLogoutFlow?

    /// Used to control the options which dictates the presentation and behavior of the sign in session.
    public var options: Option = []
    
    #if canImport(AuthenticationServices)
    /// Indicates whether or not the developer prefers an ephemeral browser session, or if the user's browser state should be shared with the system browser.
    public var ephemeralSession: Bool {
        get {
            options.contains(.ephemeralSession)
        }
        set {
            if newValue {
                options.insert(.ephemeralSession)
            } else {
                options.remove(.ephemeralSession)
            }
        }
    }
    #endif

    /// Starts sign-in using the configured client.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - context: Context options used when composing the authorization URL.
    /// - Returns: The token representing the signed-in user.
    @MainActor
    public final func signIn(from window: WindowAnchor? = nil,
                             context: AuthorizationCodeFlow.Context = .init()) async throws -> Token
    {
        if provider != nil {
            await cancel()
        }
        
        guard let redirectUri = signInFlow.client.configuration.redirectUri
        else {
            throw OAuth2Error.redirectUriRequired
        }

        async let authorizeUrl = signInFlow.start(with: context)
        let provider = try await Self.providerFactory.createWebAuthenticationProvider(
            for: self,
            from: window,
            options: options)
        self.provider = provider
        
        let url = try await provider.open(authorizeUrl: authorizeUrl,
                                          redirectUri: redirectUri)
        self.provider = nil
        
        return try await signInFlow.resume(with: url)
    }
    
    /// Starts log-out using the credential.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - credential: Stored credentials that will retrieve the ID token.
    ///   - context: Context options used when composing the signout URL.
    @discardableResult
    @MainActor
    public final func signOut(from window: WindowAnchor? = nil,
                              credential: Credential?,
                              context: SessionLogoutFlow.Context = .init()) async throws -> URL
    {
        try await signOut(from: window, token: credential?.token, context: context)
    }
    
    /// Starts log-out using the `Token` object.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - token: Token object that will retrieve the ID token.
    ///   - context: Context options used when composing the signout URL.
    @discardableResult
    @MainActor
    public final func signOut(from window: WindowAnchor? = nil,
                              token: Token?,
                              context: SessionLogoutFlow.Context = .init()) async throws -> URL
    {
        var context = context
        context.idToken = token?.idToken?.rawValue
        return try await signOut(from: window, context: context)
    }

    /// Starts log-out using the ID token.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - context: Context options used when composing the signout URL.
    @discardableResult
    @MainActor
    public final func signOut(from window: WindowAnchor?,
                              context: SessionLogoutFlow.Context = .init()) async throws -> URL
    {
        guard let signOutFlow,
              let redirectUri = signOutFlow.client.configuration.logoutRedirectUri
        else {
            throw BrowserSigninError.noSignOutFlowProvided
        }
        
        if provider != nil {
            await cancel()
        }

        async let authorizeUrl = signOutFlow.start(with: context)
        let provider = try await Self.providerFactory.createWebAuthenticationProvider(
            for: self,
            from: window,
            options: options)

        self.provider = provider
        defer { self.provider = nil }

        return try await provider.open(authorizeUrl: authorizeUrl,
                                       redirectUri: redirectUri)
    }
    
    /// Cancels the authentication session.
    @MainActor
    public final func cancel() async {
        await self.signInFlow.reset()
        await self.signOutFlow?.reset()
        provider?.cancel()
        provider = nil
    }
    
    /// Initializes a web authentiation session using client credentials defined within the application's `Okta.plist` file.
    public convenience init() throws {
        try self.init(try OAuth2Client.PropertyListConfiguration())
    }
    
    /// Initializes a web authentication session using client credentials defined within the provided file URL.
    /// - Parameter fileURL: File URL to a `plist` file containing client configuration.
    public convenience init(plist fileURL: URL) throws {
        try self.init(try OAuth2Client.PropertyListConfiguration(plist: fileURL))
    }
    
    /// Initializes a web authentication session using the supplied client credentials.
    /// - Parameters:
    ///   - issuerURL: The URL for the OAuth2 issuer.
    ///   - clientId: The client's ID.
    ///   - scope: The scopes the client is requesting.
    ///   - redirectUri: The redirect URI for the configured client.
    ///   - logoutRedirectUri: The logout URI for the client, if applicable.
    ///   - additionalParameters: Optional parameters to add to the authorization query string.
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: ClaimCollection<[String]>,
                            redirectUri: URL,
                            logoutRedirectUri: URL? = nil,
                            additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        let loginFlow = AuthorizationCodeFlow(issuerURL: issuerURL,
                                              clientId: clientId,
                                              scope: scope,
                                              redirectUri: redirectUri,
                                              logoutRedirectUri: logoutRedirectUri,
                                              additionalParameters: additionalParameters)
        let client = loginFlow.client

        let logoutFlow: SessionLogoutFlow?
        if client.configuration.logoutRedirectUri != nil {
            logoutFlow = SessionLogoutFlow(client: client,
                                           additionalParameters: additionalParameters)
        } else {
            logoutFlow = nil
        }

        self.init(loginFlow: loginFlow, logoutFlow: logoutFlow)
    }
    
    @_documentation(visibility: private)
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: some WhitespaceSeparated,
                            redirectUri: URL,
                            logoutRedirectUri: URL? = nil,
                            additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(issuerURL: issuerURL,
                  clientId: clientId,
                  scope: .init(wrappedValue: scope.whitespaceSeparated),
                  redirectUri: redirectUri,
                  logoutRedirectUri: logoutRedirectUri,
                  additionalParameters: additionalParameters)
    }
    
    convenience init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        let client = try OAuth2Client(config)
        let loginFlow = try AuthorizationCodeFlow(client: client,
                                                  additionalParameters: config.additionalParameters)
        let logoutFlow: SessionLogoutFlow?
        if client.configuration.logoutRedirectUri != nil {
            logoutFlow = SessionLogoutFlow(client: client,
                                           additionalParameters: config.additionalParameters)
        } else {
            logoutFlow = nil
        }
        
        self.init(loginFlow: loginFlow, logoutFlow: logoutFlow)
    }

    /// Initializes a web authentication session using the supplied AuthorizationCodeFlow and optional context.
    /// - Parameters:
    ///   - loginFlow: Authorization code flow instance for signing in to this client.
    ///   - logoutFlow: Session sign out flow to use when signing out from this client.
    public init(loginFlow: AuthorizationCodeFlow, logoutFlow: SessionLogoutFlow?) {
        assert(SDKVersion.browserSignin != nil)

        self.signInFlow = loginFlow
        self.signOutFlow = logoutFlow

        BrowserSignin.shared = self
    }
    
    /// Used to assign a custom ``BrowserSignin/ProviderFactory``.
    ///
    /// > Important: The default implementation will use the most appropriate browser session for use when authenticating. This facility should only be used when a built-in browser capability is unavailable in your target environment.
    public static var providerFactory: any BrowserSignin.ProviderFactory.Type = BrowserSignin.self

    // MARK: Internal members
    private static var _shared: BrowserSignin?
    
    // Used for testing only
    static func resetToDefault() {
        providerFactory = BrowserSignin.self
    }
    
    var provider: (any BrowserSignin.Provider)?
}

extension BrowserSignin: BrowserSignin.ProviderFactory {
    public nonisolated static func createWebAuthenticationProvider(
        for webAuth: BrowserSignin,
        from window: BrowserSignin.WindowAnchor?,
        options: Option) throws -> any BrowserSignin.Provider
    {
        #if canImport(AuthenticationServices)
        if #available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *) {
            return try AuthenticationServicesProvider(from: window, usesEphemeralSession: options.contains(.ephemeralSession))
        }
        #endif

        throw BrowserSigninError.noCompatibleAuthenticationProviders
    }
}

extension BrowserSignin {
    /// Asynchronously initiates authentication from the given window.
    /// - Parameters:
    ///   - window: The window from which the authentication browser should be shown.
    ///   - context: Context options used when composing the authorization URL.
    ///   - completion: Completion block that will be invoked when authentication finishes.
    public final func signIn(from window: WindowAnchor?,
                             context: AuthorizationCodeFlow.Context = .init(),
                             completion: @escaping (Result<Token, BrowserSigninError>) -> Void)
    {
        Task { @MainActor in
            do {
                completion(.success(try await signIn(from: window, context: context)))
            } catch {
                completion(.failure(BrowserSigninError(error)))
            }
        }
    }
    
    /// Asynchronous convenience method that initiates log-out using the credential object, throwing the error if fails.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - credential: Stored credentials that will retrieve the ID token.
    ///   - context: Context options used when composing the signout URL.
    ///   - completion: Completion block that will be invoked when log-out finishes.
    public final func signOut(from window: WindowAnchor?,
                              credential: Credential? = .default,
                              context: SessionLogoutFlow.Context = .init(),
                              completion: @escaping (Result<URL, BrowserSigninError>) -> Void)
    {
        Task { @MainActor in
            do {
                completion(.success(try await signOut(from: window, credential: credential, context: context)))
            } catch {
                completion(.failure(BrowserSigninError(error)))
            }
        }
    }
    
    /// Asynchronous convenience method that initiates log-out using the `Token` object, throwing the error if fails.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - token: Token object that will retrieve the ID token.
    ///   - context: Context options used when composing the signout URL.
    ///   - completion: Completion block that will be invoked when sign-out finishes.
    public final func signOut(from window: WindowAnchor?,
                              token: Token,
                              context: SessionLogoutFlow.Context = .init(),
                              completion: @escaping (Result<URL, BrowserSigninError>) -> Void)
    {
        Task { @MainActor in
            do {
                completion(.success(try await signOut(from: window, token: token, context: context)))
            } catch {
                completion(.failure(BrowserSigninError(error)))
            }
        }
    }
    
    /// Asynchronous convenience method that initiates log-out using the ID Token, throwing the error if fails.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - context: Context options used when composing the signout URL.
    ///   - completion: Completion block that will be invoked when sign-out finishes.
    public final func signOut(from window: WindowAnchor?,
                              context: SessionLogoutFlow.Context = .init(),
                              completion: @escaping (Result<URL, BrowserSigninError>) -> Void)
    {
        Task { @MainActor in
            do {
                completion(.success(try await signOut(from: window, context: context)))
            } catch {
                completion(.failure(BrowserSigninError(error)))
            }
        }
    }
}
