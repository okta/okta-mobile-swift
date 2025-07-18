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
    case noAuthenticatorProviderResonse
    case serverError(_ error: OAuth2ServerError)
    case invalidRedirectScheme(_ scheme: String?)
    case userCancelledLogin
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
///  > Important: If your application targets iOS 9.x-10.x, you should add the redirect URI for your client configuration to your app's supported URL schemes.  This is because users on devices older than iOS 11 will be prompted to sign in using `SFSafariViewController`, which does not allow your application to detect the final token redirect.
@MainActor
@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
public final class BrowserSignin {
    #if os(macOS)
    public typealias WindowAnchor = NSWindow
    #elseif os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
    public typealias WindowAnchor = UIWindow
    #else
    public typealias WindowAnchor = Void
    #endif
    
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
    public let signInFlow: AuthorizationCodeFlow
    
    /// The underlying OAuth2 flow that implements the session logout behaviour.
    public let signOutFlow: SessionLogoutFlow?
    
    /// Indicates whether or not the developer prefers an ephemeral browser session, or if the user's browser state should be shared with the system browser.
    public var ephemeralSession: Bool = false
    
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
        guard let provider = try await Self.providerFactory.createWebAuthenticationProvider(
            for: self,
            from: window,
            usesEphemeralSession: ephemeralSession)
        else {
            throw BrowserSigninError.noCompatibleAuthenticationProviders
        }
        
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
        guard let provider = try await Self.providerFactory.createWebAuthenticationProvider(
            for: self,
            from: window,
            usesEphemeralSession: ephemeralSession)
        else {
            throw BrowserSigninError.noCompatibleAuthenticationProviders
        }

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
                            additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        let client = OAuth2Client(issuerURL: issuerURL,
                                  clientId: clientId,
                                  scope: scope,
                                  redirectUri: redirectUri,
                                  logoutRedirectUri: logoutRedirectUri)
        try self.init(client: client, additionalParameters: additionalParameters)
    }
    
    @_documentation(visibility: private)
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: some WhitespaceSeparated,
                            redirectUri: URL,
                            logoutRedirectUri: URL? = nil,
                            additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        let client = OAuth2Client(issuerURL: issuerURL,
                                  clientId: clientId,
                                  scope: scope,
                                  redirectUri: redirectUri,
                                  logoutRedirectUri: logoutRedirectUri)
        try self.init(client: client, additionalParameters: additionalParameters)
    }
    
    convenience init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        try self.init(client: OAuth2Client(config),
                      additionalParameters: config.additionalParameters)
    }
    
    convenience init(client: OAuth2Client, additionalParameters: [String: any APIRequestArgument]?) throws {
        let loginFlow = try AuthorizationCodeFlow(client: client,
                                                  additionalParameters: additionalParameters)
        let logoutFlow: SessionLogoutFlow?
        if client.configuration.logoutRedirectUri != nil {
            logoutFlow = SessionLogoutFlow(client: client,
                                           additionalParameters: additionalParameters)
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
    
    // MARK: Internal members
    private static var _shared: BrowserSignin?
    static var providerFactory: any BrowserSigninProviderFactory.Type = BrowserSignin.self
    
    // Used for testing only
    static func resetToDefault() {
        providerFactory = BrowserSignin.self
    }
    
    var provider: (any BrowserSigninProvider)?
}

@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
extension BrowserSignin: BrowserSigninProviderFactory {
    nonisolated static func createWebAuthenticationProvider(
        for webAuth: BrowserSignin,
        from window: BrowserSignin.WindowAnchor?,
        usesEphemeralSession: Bool = false) throws -> (any BrowserSigninProvider)?
    {
        try AuthenticationServicesProvider(from: window, usesEphemeralSession: usesEphemeralSession)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
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
