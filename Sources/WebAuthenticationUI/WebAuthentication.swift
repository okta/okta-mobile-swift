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
    case noCompatibleAuthenticationProviders
    case cannotComposeAuthenticationURL
    case authenticationProviderError(_ error: Error)
    case serverError(_ error: OAuth2ServerError)
    case invalidRedirectScheme(_ scheme: String?)
    case userCancelledLogin
    case missingIdToken
    case oauth2(error: OAuth2Error)
    case generic(error: Error)
    case genericError(message: String)
}

/// Authentication coordinator that simplifies signing users in using browser-based OIDC authentication flows.
///
/// This simple class encapsulates the details of managing browser instances across iOS/macOS versions, coordinating with OAuth2 endpoints, and supporting a variety of conveniences when signing users into your application.
///
/// The simplest way to authenticate a user is to use the ``shared`` property to access your default session, and calling ``signIn(from:)`` to present the browser to the user.
///
/// ```swift
/// let token = try await WebAuthentication.shared?.signIn(from: view.window)
/// ```
///
/// To customize the authentication flow, please read more about the underlying OAuth2 client within the OktaOAuth2 library, and how that relates to the ``signInFlow`` or ``signOutFlow`` properties.
///
///  > Important: If your application targets iOS 9.x-10.x, you should add the redirect URI for your client configuration to your app's supported URL schemes.  This is because users on devices older than iOS 11 will be prompted to sign in using `SFSafariViewController`, which does not allow your application to detect the final token redirect.
public class WebAuthentication {
    #if os(macOS)
    public typealias WindowAnchor = NSWindow
    #else
    public typealias WindowAnchor = UIWindow
    #endif
    
    /// Describes available options for customizing the sign on process.
    public enum Option {
        /// The username to pre-populate if prompting for authentication.
        case login(hint: String)
        
        /// Value passed to the Social IdP when performing social login.
        case display(String)
        
        /// Allowable elapsed time since the user was last authenticated.
        case maxAge(TimeInterval)
        
        /// Specify a custom state to use when authorizing.
        ///
        /// If this value is not specified, one will be automatically generated.
        case state(String)

        /// Identity Provider to use if there's no Okta session.
        case idp(url: URL)

        /// Identity Provider to use if there's no Okta session.
        case idpScope(String)
        
        /// Control how the user is prompted when authentication starts.
        ///
        /// > Note: The default behavior is ``Prompt/none``.
        case prompt(Prompt)
        
        /// Supply a custom key/value pair to the authorization server.
        case custom(key: String, value: String)
        
        /// Defines how a user will be prompted to sign in.
        ///
        /// This is used with the ``WebAuthentication/Option/prompt(_:)`` enumeration. For more information, see the [API documentation for this parameter](https://developer.okta.com/docs/reference/api/oidc/#parameter-details).
        public enum Prompt: String {
            /// If an Okta session already exists, the user is silently authenticated. Otherwise, the user is prompted to authenticate.
            case none
            
            /// Display the Okta consent dialog, even if the user has already given consent.
            case consent
            
            /// Always prompt the user for authentication.
            case login
            
            /// The user is always prompted for authentication, and the user consent dialog appears.
            case loginAndConsent = "login consent"
        }
    }
    
    /// Active / default shared instance of the ``WebAuthentication`` session.
    ///
    /// This convenience property can be used in one of two ways:
    ///
    /// 1. Access a shared instance using the settings configured within a file named `Okta.plist`
    /// 2. Programmatically create an instance that can be shared across your application.
    ///
    /// For more information on how to configure your client, see <doc:ConfiguringYourClient> for more details.
    public private(set) static var shared: WebAuthentication? {
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
    public let signInFlow: AuthorizationCodeFlow
    
    /// The underlying OAuth2 flow that implements the session logout behaviour.
    public let signOutFlow: SessionLogoutFlow?
    
    /// Context information about the current authorization code flow.
    ///
    /// This represents the state and other challenge data necessary to resume the authentication flow.
    ///
    /// > Warning: This is deprecated, and will be removed in a future release.
    @available(*, deprecated, renamed: "signInFlow.context")
    public var context: AuthorizationCodeFlow.Context? {
        signInFlow.context
    }
    
    /// Indicates whether or not the developer prefers an ephemeral browser session, or if the user's browser state should be shared with the system browser.
    public var ephemeralSession: Bool = false
    
    /// Starts sign-in using the configured client.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - options: Options to add to the authorization URL.
    ///   - completion: Completion block that will be invoked when authentication finishes.
    public final func signIn(from window: WindowAnchor?,
                             options: [Option]? = nil,
                             completion: @escaping (Result<Token, WebAuthenticationError>) -> Void)
    {
        if provider != nil {
            cancel()
        }
        
        let provider = createWebAuthenticationProvider(loginFlow: signInFlow,
                                                       logoutFlow: signOutFlow,
                                                       from: window,
                                                       delegate: self)
        self.completionBlock = completion
        self.provider = provider

        provider?.start(context: options?.context,
                        additionalParameters: options?.additionalParameters)
    }
    
    /// Starts log-out using the credential.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - credential: Stored credentials that will retrieve the ID token.
    ///   - options: Options to add to the authorization URL.
    ///   - completion: Completion block that will be invoked when log-out finishes.
    public final func signOut(from window: WindowAnchor? = nil,
                              credential: Credential? = .default,
                              options: [Option]? = nil,
                              completion: @escaping (Result<Void, WebAuthenticationError>) -> Void)
    {
        guard let token = credential?.token else {
            completion(.failure(.missingIdToken))
            return
        }
        
        signOut(from: window, token: token, options: options, completion: completion)
    }
    
    /// Starts log-out using the `Token` object.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - token: Token object that will retrieve the ID token.
    ///   - options: Options to add to the authorization URL.
    ///   - completion: Completion block that will be invoked when sign-out finishes.
    public final func signOut(from window: WindowAnchor? = nil,
                              token: Token,
                              options: [Option]? = nil,
                              completion: @escaping (Result<Void, WebAuthenticationError>) -> Void)
    {
        guard let idToken = token.idToken else {
            completion(.failure(.missingIdToken))
            return
        }
        
        signOut(from: window, token: idToken.rawValue, options: options, completion: completion)
    }

    /// Starts log-out using the ID token.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - token: The ID token string used for log-out.
    ///   - options: Options to add to the authorization URL.
    ///   - completion: Completion block that will be invoked when sign-out finishes.
    public final func signOut(from window: WindowAnchor? = nil,
                              token: String,
                              options: [Option]? = nil,
                              completion: @escaping (Result<Void, WebAuthenticationError>) -> Void)
    {
        var provider = provider
        
        if provider != nil {
            cancel()
        }
        
        provider = createWebAuthenticationProvider(loginFlow: signInFlow,
                                                   logoutFlow: signOutFlow,
                                                   from: window,
                                                   delegate: self)
        
        self.logoutCompletionBlock = completion
        self.provider = provider
        
        let context = SessionLogoutFlow.Context(idToken: token,
                                                state: options?.state)
        provider?.logout(context: context,
                         additionalParameters: options?.additionalParameters)
    }
    
    /// Cancels the authentication session.
    public final func cancel() {
        signInFlow.reset()
        signOutFlow?.reset()
        provider?.cancel()
        provider = nil
    }
    
    #if os(iOS)
    /// Attempts to resume sign in when the app is launched from a redirect URI.
    ///
    /// This is a convenience method that can simplify apps that use a UISceneDelegate. Scene-based applications receive URLs when the `UIWindowSceneDelegate.scene(_:openURLContexts:)` method is called; the set of contexts can be supplied to this method, which will filter out only those URLs that match the URL scheme defined in the client configuration. If no matching URLs are found, the call is ignored.
    /// - Parameter URLContexts: Set of `UIOpenURLContext` objects from which to attempt to resume authentication.
    @available(iOS 13.0, *)
    public final func resume(with URLContexts: Set<UIOpenURLContext>) throws {
        try URLContexts
            .filter { $0.url.scheme?.lowercased() == signInFlow.redirectUri.scheme?.lowercased() }
            .map(\.url)
            .forEach(resume(with:))
    }
    #endif
    
    /// Attempts to resume sign in when the app is launched from a redirect URI.
    ///
    /// This method is used when the sign in process continues outside of the application and its embedded authentication browser. When the application is opened using this redirect URI, this method can be used to resume the flow using that URL.
    ///
    /// If the URI does not match the configured URI scheme, this method will thrown an error.
    /// - Parameter url: URL from which to attempt to resume authentication.
    public final func resume(with url: URL) throws {
        guard url.scheme?.lowercased() == signInFlow.redirectUri.scheme?.lowercased()
        else {
            throw WebAuthenticationError.invalidRedirectScheme(url.scheme)
        }
        
        try signInFlow.resume(with: url) { _ in
            self.provider = nil
        }
        
        self.provider?.cancel()
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
    ///   - issuer: The URL for the OAuth2 issuer.
    ///   - clientId: The client's ID.
    ///   - scopes: The scopes the client is requesting.
    ///   - redirectUri: The redirect URI for the configured client.
    ///   - logoutRedirectUri: The logout URI for the client, if applicable.
    ///   - additionalParameters: Optional parameters to add to the authorization query string.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            redirectUri: URL,
                            logoutRedirectUri: URL? = nil,
                            additionalParameters: [String: String]? = nil)
    {
        let client = OAuth2Client(baseURL: issuer,
                                  clientId: clientId,
                                  scopes: scopes)
        
        let logoutFlow: SessionLogoutFlow?
        if let logoutRedirectUri = logoutRedirectUri {
            logoutFlow = SessionLogoutFlow(logoutRedirectUri: logoutRedirectUri,
                                           additionalParameters: additionalParameters,
                                           client: client)
        } else {
            logoutFlow = nil
        }
        
        self.init(loginFlow: AuthorizationCodeFlow(redirectUri: redirectUri,
                                                   additionalParameters: additionalParameters,
                                                   client: client),
                  logoutFlow: logoutFlow)
    }
    
    convenience init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        guard let redirectUri = config.redirectUri else {
            throw OAuth2Client.PropertyListConfigurationError.missingConfigurationValues
        }
        
        self.init(issuer: config.issuer,
                  clientId: config.clientId,
                  scopes: config.scopes,
                  redirectUri: redirectUri,
                  logoutRedirectUri: config.logoutRedirectUri,
                  additionalParameters: config.additionalParameters)
    }
    
    func createWebAuthenticationProvider(loginFlow: AuthorizationCodeFlow,
                                         logoutFlow: SessionLogoutFlow?,
                                         from window: WebAuthentication.WindowAnchor?,
                                         delegate: WebAuthenticationProviderDelegate) -> WebAuthenticationProvider?
    {
        if #available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *) {
            return AuthenticationServicesProvider(loginFlow: loginFlow,
                                                  logoutFlow: logoutFlow,
                                                  from: window,
                                                  delegate: delegate)
        }
        
        #if os(iOS)
        if #available(iOS 11.0, *) {
            return SafariServicesProvider(loginFlow: loginFlow,
                                          logoutFlow: logoutFlow,
                                          delegate: delegate)
        }
        
        if #available(iOS 10.0, *) {
            return SafariBrowserProvider(loginFlow: loginFlow,
                                         logoutFlow: logoutFlow,
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
    ///
    /// > Warning: This is deprecated, and will be removed in a future release.
    @available(*, deprecated, renamed: "init(loginFlow:logoutFlow:)")
    public convenience init(loginFlow: AuthorizationCodeFlow, logoutFlow: SessionLogoutFlow?, context: AuthorizationCodeFlow.Context?) {
        self.init(loginFlow: loginFlow, logoutFlow: logoutFlow)
    }
    
    /// Initializes a web authentication session using the supplied AuthorizationCodeFlow and optional context.
    /// - Parameters:
    ///   - flow: Authorization code flow instance for this client.
    ///   - context: Optional context to initialize authentication with.
    public init(loginFlow: AuthorizationCodeFlow, logoutFlow: SessionLogoutFlow?) {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.signInFlow = loginFlow
        self.signOutFlow = logoutFlow

        WebAuthentication.shared = self
    }
    
    // MARK: Internal members
    private static var _shared: WebAuthentication?
    var provider: WebAuthenticationProvider?
    var completionBlock: ((Result<Token, WebAuthenticationError>) -> Void)?
    var logoutCompletionBlock: ((Result<Void, WebAuthenticationError>) -> Void)?
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension WebAuthentication {
    /// Asynchronously initiates authentication from the given window.
    /// - Parameters:
    ///   - window: The window from which the authentication browser should be shown.
    ///   - options: Options to add to the authorization URL.
    /// - Returns: The token representing the signed-in user.
    public final func signIn(from window: WindowAnchor?,
                             options: [Option]? = nil) async throws -> Token
    {
        try await withCheckedThrowingContinuation { continuation in
            self.signIn(from: window, options: options) { continuation.resume(with: $0) }
        }
    }
    
    /// Asynchronous convenience method that initiates log-out using the credential object, throwing the error if fails.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - credential: Stored credentials that will retrieve the ID token.
    ///   - options: Options to add to the authorization URL.
    public final func signOut(from window: WindowAnchor?,
                              credential: Credential? = .default,
                              options: [Option]? = nil) async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            self.signOut(from: window, credential: credential, options: options) { continuation.resume(with: $0) }
        }
    }
    
    /// Asynchronous convenience method that initiates log-out using the `Token` object, throwing the error if fails.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - token: Token object that will retrieve the ID token.
    ///   - options: Options to add to the authorization URL.
    public final func signOut(from window: WindowAnchor?,
                              token: Token,
                              options: [Option]? = nil) async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            self.signOut(from: window, token: token, options: options) { continuation.resume(with: $0) }
        }
    }
    
    /// Asynchronous convenience method that initiates log-out using the ID Token, throwing the error if fails.
    /// - Parameters:
    ///   - window: Window from which the sign in process will be started.
    ///   - idToken: The ID token used for log-out.
    ///   - options: Options to add to the authorization URL.
    public final func signOut(from window: WindowAnchor?,
                              token: String,
                              options: [Option]? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.signOut(from: window, token: token, options: options) { continuation.resume(with: $0) }
        }
    }
}
#endif
#endif
