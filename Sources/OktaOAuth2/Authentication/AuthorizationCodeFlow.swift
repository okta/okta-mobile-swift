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

import Foundation
import AuthFoundation

/// The delegate of a ``AuthorizationCodeFlow`` may adopt some, or all, of the methods described here. These allow a developer to customize or interact with the authentication flow during authentication.
///
/// This protocol extends the basic `AuthenticationDelegate` which all authentication flows support.
public protocol AuthorizationCodeFlowDelegate: AuthenticationDelegate {
    /// Called before authentication begins.
    /// - Parameters:
    ///   - flow: The authentication flow that has started.
    func authenticationStarted<Flow: AuthorizationCodeFlow>(flow: Flow)

    /// Called after authentication completes.
    /// - Parameters:
    ///   - flow: The authentication flow that has finished.
    func authenticationFinished<Flow: AuthorizationCodeFlow>(flow: Flow)

    /// Provides the opportunity to customize the authorization URL.
    ///
    /// The authorization URL is generated from a combination of configuration sources, as well as the issuer's OpenID configuration. When specific values need to be added to the URL, such as custom query string or other URL parameters, this delegate method enables you to manipulate the URL before it is passed to a web browser.
    /// - Parameters:
    ///   - flow: The authentication flow.
    ///   - urlComponents: A `URLComponents` instance that represents the authorization URL, prior to conversion to a URL.
    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents)
    
    /// Called when the authorization URL has been created, indicating the URL should be presented to the user.
    /// - Parameters:
    ///   - flow: The authentication flow.
    ///   - url: The authorization URL to display in a browser to the user.
    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, shouldAuthenticateUsing url: URL)
}

/// An authentication flow class that implements the Authorization Code Flow exchange.
///
/// The Authorization Code Flow permits a user to authenticate using a web browser redirect model, where an initial authentication URL is loaded in a browser, they sign in through some external service, after which their browser is redirected to a URL whose scheme matches the one defined in the client configuration. An authorization code is included in that URL's query string parameters. This code can then be exchanged against the authorization server for access tokens.
///
/// You can create an instance of  ``AuthorizationCodeFlow`` with your client settings, along with the matching `OAuth2Client` for performing key operations and requests. Alternatively, you can use any of the convenience initializers to simplify the process.
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``AuthorizationCodeFlow`` can just as easily be used with completion blocks or through the use of the ``AuthorizationCodeFlowDelegate``.
///
/// ```swift
/// let flow = AuthorizationCodeFlow(
///     issuer: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scopes: "openid offline_access email profile",
///     redirectUri: URL(string: "com.example.app:/callback"))
///
/// // Create the authorization URL. Open this in a browser.
/// let authorizeUrl = try await flow.start()
///
/// // Once the browser redirects to the callback scheme
/// // from the redirect URI, use that to resume the flow.
/// let redirectUri: URL
/// let token = try await flow.resume(with: redirectUri)
/// ```
public class AuthorizationCodeFlow: AuthenticationFlow {
    /// A model representing the context and current state for an authorization session.
    public struct Context: Equatable {
        /// The `PKCE` credentials to use in the authorization request.
        ///
        /// This value may be `nil` on platforms that do not support PKCE.
        public let pkce: PKCE?
        
        /// The state string to use when creating an authentication URL.
        public let state: String
        
        /// The "nonce" value to send with this authorization request.
        public let nonce: String
        
        /// The maximum age an ID token can be when authenticating.
        public let maxAge: TimeInterval?
        
        /// The current authentication URL, or `nil` if one has not yet been generated.
        public internal(set) var authenticationURL: URL?
        
        /// Initializer for creating a context with a custom state string.
        /// - Parameters:
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        ///   - maxAge: The maximum age an ID token can be when authenticating.
        public init(state: String? = nil, maxAge: TimeInterval? = nil) {
            self.init(state: state ?? UUID().uuidString,
                      maxAge: maxAge,
                      nonce: [UInt8].random(count: 16).base64URLEncodedString,
                      pkce: PKCE())
        }
        
        init(state: String, maxAge: TimeInterval?, nonce: String, pkce: PKCE?) {
            self.state = state
            self.maxAge = maxAge
            self.nonce = nonce
            self.pkce = pkce
        }
    }
    
    /// Errors reported during processing and handling of redirect URLs.
    ///
    /// These errors are mostly reported as a result of the ``start(with:additionalParameters:completion:)`` or ``start(with:additionalParameters:)`` methods.
    public enum RedirectError: Error, Equatable {
        case invalidRedirectUrl
        case unexpectedScheme(_ scheme: String?)
        case missingQueryArguments
        case invalidState(_ state: String?)
        case missingAuthorizationCode
    }
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The redirect URI defined for your client.
    public let redirectUri: URL
    
    /// Any additional query string parameters you would like to supply to the authorization server.
    public let additionalParameters: [String: String]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    public private(set) var isAuthenticating: Bool = false {
        didSet {
            guard oldValue != isAuthenticating else {
                return
            }
            
            if isAuthenticating {
                delegateCollection.invoke { $0.authenticationStarted(flow: self) }
            } else {
                delegateCollection.invoke { $0.authenticationFinished(flow: self) }
            }
        }
    }
    
    /// The context that stores the state for the current authentication session.
    public private(set) var context: Context? {
        didSet {
            guard let url = context?.authenticationURL else {
                return
            }

            delegateCollection.invoke { $0.authentication(flow: self, shouldAuthenticateUsing: url) }
        }
    }
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scopes: The scopes to request.
    ///   - redirectUri: The redirect URI for the client.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            redirectUri: URL,
                            additionalParameters: [String: String]? = nil)
    {
        self.init(redirectUri: redirectUri,
                  additionalParameters: additionalParameters,
                  client: .init(baseURL: issuer,
                                clientId: clientId,
                                scopes: scopes))
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - redirectUri: The redirect URI for the client.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(redirectUri: URL,
                additionalParameters: [String: String]? = nil,
                client: OAuth2Client)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.redirectUri = redirectUri
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Initializer that uses the configuration defined within the application's `Okta.plist` file.
    public convenience init() throws {
        try self.init(try .init())
    }
    
    /// Initializer that uses the configuration defined within the given file URL.
    /// - Parameter fileURL: File URL to a `plist` containing client configuration.
    public convenience init(plist fileURL: URL) throws {
        try self.init(try .init(plist: fileURL))
    }
    
    private convenience init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        guard let redirectUri = config.redirectUri else {
            throw OAuth2Client.PropertyListConfigurationError.missingConfigurationValues
        }

        self.init(issuer: config.issuer,
                  clientId: config.clientId,
                  scopes: config.scopes,
                  redirectUri: redirectUri,
                  additionalParameters: config.additionalParameters)
    }
    
    /// Initiates an authentication flow, with an optional ``Context-swift.struct``.
    ///
    /// This method is used to begin an authentication session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    ///   - completion: Completion block for receiving the response.
    public func start(with context: Context? = nil,
                      additionalParameters: [String: String]? = nil,
                      completion: @escaping (Result<URL, OAuth2Error>) -> Void)
    {
        var context = context ?? Context()
        isAuthenticating = true

        client.openIdConfiguration { result in
            switch result {
            case .failure(let error):
                self.reset()
                
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                completion(.failure(error))
            case .success(let configuration):
                do {
                    let url = try self.createAuthenticationURL(from: configuration.authorizationEndpoint,
                                                               using: context,
                                                               additionalParameters: additionalParameters)
                    context.authenticationURL = url
                    self.context = context
                    
                    completion(.success(url))
                } catch {
                    self.reset()
                    
                    let oauthError = error as? OAuth2Error ?? .error(error)
                    self.delegateCollection.invoke { $0.authentication(flow: self, received: oauthError) }
                    completion(.failure(oauthError))
                }
            }
        }
    }
    
    /// Continues an authentication flow using the given authentication redirect URI.
    ///
    /// Once the user completes authorization, using the URL provided by the ``start(with:additionalParameters:completion:)`` method within a browser, the browser will redirect to a URL that matches the scheme provided in the client configuration's ``redirectUri``. This URI will contain either an error response from the authorization server, or an authorization code which can be used to exchange a token.
    ///
    /// This method takes the returned redirect URI, and communicates with Okta to exchange that for a token.
    /// - Parameters:
    ///   - url: Authorization redirect URI
    ///   - completion: Completion block to retrieve the returned result.
    public func resume(with url: URL, completion: @escaping (Result<Token, OAuth2Error>) -> Void) throws {
        let code = try authorizationCode(from: url)
        
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = TokenRequest(openIdConfiguration: configuration,
                                           clientConfiguration: self.client.configuration,
                                           redirectUri: self.redirectUri.absoluteString,
                                           grantType: .authorizationCode,
                                           grantValue: code,
                                           pkce: self.context?.pkce,
                                           nonce: self.context?.nonce,
                                           maxAge: self.context?.maxAge)
                self.client.exchange(token: request) { result in
                    self.reset()
                    
                    switch result {
                    case .success(let response):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                        completion(.success(response.result))
                    case .failure(let error):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                        completion(.failure(.network(error: error)))
                    }
                }
                
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                completion(.failure(error))
            }
        }
    }
    
    public func reset() {
        context = nil
        isAuthenticating = false
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthorizationCodeFlowDelegate>()
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension AuthorizationCodeFlow {
    /// Asynchronously initiates an authentication flow, with an optional ``Context-swift.struct``, using Swift Concurrency.
    ///
    /// This method is used to begin an authentication session.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    /// - Returns: The URL a user should be presented with within a browser, to continue authorization.
    public func start(with context: Context? = nil, additionalParameters: [String: String]? = nil) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            start(with: context, additionalParameters: additionalParameters) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Asynchronously continues an authentication flow using the given authentication redirect URI, using Swift Concurrency.
    ///
    /// Once the user completes authorization, using the URL provided by the ``start(with:additionalParameters:)`` method within a browser, the browser will redirect to a URL that matches the scheme provided in the client configuration's ``redirectUri``. This URI will contain either an error response from the authorization server, or an authorization code which can be used to exchange a token.
    ///
    /// This method takes the returned redirect URI, and communicates with Okta to exchange that for a token.
    /// - Parameters:
    ///   - url: Authorization redirect URI.
    /// - Returns: The Token created as a result of exchanging an authorization code.
    public func resume(with url: URL) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try resume(with: url) { result in
                    continuation.resume(with: result)
                }
            } catch let error as APIClientError {
                continuation.resume(with: .failure(error))
            } catch {
                continuation.resume(with: .failure(APIClientError.serverError(error)))
            }
        }
    }
}
#endif

extension AuthorizationCodeFlow: UsesDelegateCollection {
    public typealias Delegate = AuthorizationCodeFlowDelegate
}

extension AuthorizationCodeFlow {
    func authorizationCode(from url: URL) throws -> String {
        guard let context = context else {
            throw AuthenticationError.flowNotReady
        }
        
        return try url.authorizationCode(redirectUri: redirectUri, state: context.state)
    }
}

extension AuthorizationCodeFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    public func authorizationCodeFlow(
        redirectUri: URL,
        additionalParameters: [String: String]? = nil) -> AuthorizationCodeFlow
    {
        AuthorizationCodeFlow(redirectUri: redirectUri,
                              additionalParameters: additionalParameters,
                              client: self)
    }
}
