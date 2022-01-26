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
/// This protocol extends the basic ``AuthenticationDelegate`` which all authentication flows support.
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
/// You can create an instance of  ``AuthorizationCodeFlow/Configuration-swift.struct`` to define your client's settings, and supply that to the initializer, along with a reference to your OAuth2Client for performing key operations and requests. Alternatively, you can use any of the convenience initializers to simplify the process.
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
/// let authorizeUrl = try await flow.resume()
///
/// // Once the browser redirects to the callback scheme
/// // from the redirect URI, use that to resume the flow.
/// let redirectUri: URL
/// let token = try await flow.resume(with: redirectUri)
/// ```
public class AuthorizationCodeFlow: AuthenticationFlow {
    /// Configuration settings that define the OAuth2 client to be authenticated against.
    
    public struct Configuration: AuthenticationConfiguration {
        /// The client's ID.
        public let clientId: String
        
        /// The client secret, if applicable to your application.
        public let clientSecret: String?
        
        /// The scopes requested.
        public let scopes: String
        
        /// The response type expected.
        public let responseType: ResponseType
        
        /// The redirect URI defined for your client.
        public let redirectUri: URL
        
        /// The logout redirect URI, if applicable.
        public let logoutRedirectUri: URL?
        
        /// Any additional query string parameters you would like to supply to the authorization server.
        public let additionalParameters: [String:String]?
        
        /// Convenience initializer for constructing an authorization code flow configuration using the supplied values.
        /// - Parameters:
        ///   - clientId: The client's ID
        ///   - clientSecret: The client's secret, if applicable
        ///   - state: The state to use in the authorization URL, or `nil` to accept an auto-generated value.
        ///   - scopes: The scopes to request
        ///   - responseType: The response type expected, which defaults to `.code`
        ///   - redirectUri: The redirect URI for the client
        ///   - logoutRedirectUri: The logout redirect URI, if applicable
        ///   - additionalParameters: Additional query string parameters to provide, or `nil` for no custom parameters.
        public init(clientId: String,
                    clientSecret: String? = nil,
                    state: String? = nil,
                    scopes: String,
                    responseType: ResponseType = .code,
                    redirectUri: URL,
                    logoutRedirectUri: URL? = nil,
                    additionalParameters: [String:String]? = nil)
        {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.scopes = scopes
            self.responseType = responseType
            self.redirectUri = redirectUri
            self.logoutRedirectUri = logoutRedirectUri
            self.additionalParameters = additionalParameters
        }
    }
    
    /// A model representing the context and current state for an authorization session.
    public struct Context: Codable, Equatable {
        /// The ``PKCE`` credentials to use in the authorization request.
        ///
        /// This value may be `nil` on platforms that do not support PKCE.
        public let pkce: PKCE?
        
        /// The state string to use when creating an authentication URL.
        public let state: String
        
        /// The current authentication URL, or `nil` if one has not yet been generated.
        internal(set) public var authenticationURL: URL?
        
        /// Initializer for creating a context with a custom state string.
        /// - Parameter state: State string to use, or `nil` to accept an automatically generated default.
        public init(state: String? = nil) {
            self.init(state: state ?? UUID().uuidString,
                      pkce: PKCE())
        }
        
        init(state: String, pkce: PKCE?) {
            self.state = state
            self.pkce = pkce
        }
    }
    
    /// Errors reported during processing and handling of redirect URLs.
    ///
    /// These errors are mostly reported as a result of the ``resume(with:completion:)-6a7pf`` or ``resume(with:)-10rbh`` methods.
    public enum RedirectError: Error {
        case invalidRedirectUrl
        case unexpectedScheme(_ scheme: String?)
        case missingQueryArguments
        case invalidState(_ state: String?)
        case missingAuthorizationCode
    }
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The configuration used when constructing this authentication flow.
    public let configuration: Configuration
    
    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    private(set) public var isAuthenticating: Bool = false {
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
    private(set) public var context: Context? {
        didSet {
            guard let url = context?.authenticationURL else {
                return
            }

            delegateCollection.invoke { $0.authentication(flow: self, shouldAuthenticateUsing: url) }
        }
    }
    
    /// The OpenID configuration retrieved from the authorization server.
    ///
    /// This value may be `nil` if the authentication session hasn't been started.
    private(set) public var openIdConfiguration: OpenIdConfiguration?
    
    /// The callback URL scheme this client expects to see when a redirection occurs.
    public lazy var callbackScheme: String? = {
        configuration.redirectUri.scheme
    }()
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID
    ///   - scopes: The scopes to request
    ///   - responseType: The response type to expect, or ``ResponseType/code`` if not specified.
    ///   - redirectUri: The redirect URI for the client.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            responseType: ResponseType = .code,
                            redirectUri: URL)
    {
        self.init(Configuration(clientId: clientId,
                                clientSecret: nil,
                                scopes: scopes,
                                responseType: responseType,
                                redirectUri: redirectUri),
                  client: OAuth2Client(baseURL: issuer))
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }
    
    /// Initiates an authentication flow, with an optional ``Context-swift.struct``.
    ///
    /// This method is used to begin an authentication session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func resume(with context: Context? = nil, completion: ((Result<URL,OAuth2Error>) -> Void)? = nil) throws {
        var context = context ?? Context()
        isAuthenticating = true

        client.openIdConfiguration { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                completion?(.failure(error))
            case .success(let configuration):
                self.openIdConfiguration = configuration
                
                do {
                    let url = try self.createAuthenticationURL(from: configuration.authorizationEndpoint,
                                                               using: context)
                    context.authenticationURL = url
                    self.context = context
                    
                    completion?(.success(url))
                } catch {
                    let oauthError = error as? OAuth2Error ?? .error(error)
                    self.delegateCollection.invoke { $0.authentication(flow: self, received: oauthError) }
                    completion?(.failure(oauthError))
                }
            }
        }
    }
    
    /// Continues an authentication flow using the given authentication redirect URI.
    ///
    /// Once the user completes authorization, using the URL provided by the ``resume(with:completion:)-uy9b`` method within a browser, the browser will redirect to a URL that matches the scheme provided in the client configuration's ``Configuration-swift.struct/redirectUri``. This URI will contain either an error response from the authorization server, or an authorization code which can be used to exchange a token.
    ///
    /// This method takes the returned redirect URI, and communicates with Okta to exchange that for a token.
    /// - Parameters:
    ///   - url: Authorization redirect URI
    ///   - completion: Optional completion block to retrieve the returned result.
    public func resume(with url: URL, completion: ((Result<Token,APIClientError>) -> Void)? = nil) throws {
        let code = try authorizationCode(from: url)

        let request = TokenRequest(clientId: configuration.clientId,
                                   clientSecret: configuration.clientSecret,
                                   scope: configuration.scopes,
                                   redirectUri: configuration.redirectUri.absoluteString,
                                   grantType: .authorizationCode,
                                   grantValue: code,
                                   pkce: context?.pkce)
        client.exchange(token: request) { result in
            switch result {
            case .success(let response):
                let token = response.result
                self.delegateCollection.invoke { $0.authentication(flow: self, received: token) }
                completion?(.success(token))
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                completion?(.failure(error))
            }
            
            self.context = nil
            self.isAuthenticating = false
        }
    }
    
    public func cancel() {}
    
    public func reset() {
        context = nil
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthorizationCodeFlowDelegate>()
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension AuthorizationCodeFlow {
    /// Asynchronously initiates an authentication flow, with an optional ``Context-swift.struct``, using Swift Concurrency.
    ///
    /// This method is used to begin an authentication session.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    /// - Returns: The URL a user should be presented with within a browser, to continue authorization.
    public func resume(with context: Context? = nil) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try resume(with: context) { result in
                    continuation.resume(with: result)
                }
            } catch let error as APIClientError {
                continuation.resume(with: .failure(error))
            } catch {
                continuation.resume(with: .failure(APIClientError.serverError(error)))
            }
        }
    }
    
    /// Asynchronously continues an authentication flow using the given authentication redirect URI, using Swift Concurrency.
    ///
    /// Once the user completes authorization, using the URL provided by the ``resume(with:)-10rbh`` method within a browser, the browser will redirect to a URL that matches the scheme provided in the client configuration's ``Configuration-swift.struct/redirectUri``. This URI will contain either an error response from the authorization server, or an authorization code which can be used to exchange a token.
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
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw RedirectError.invalidRedirectUrl
        }
        
        guard components.scheme?.lowercased() == callbackScheme?.lowercased() else {
            throw RedirectError.unexpectedScheme(components.scheme)
        }
        
        guard let query = components.queryItems?.reduce(into: [String:String](), { partialResult, queryItem in
            if let value = queryItem.value {
                partialResult[queryItem.name] = value
            }
        }) else {
            throw RedirectError.missingQueryArguments
        }
        
        guard query["state"] == context.state else {
            throw RedirectError.invalidState(query["state"])
        }
        
        if let errorCode = query["error"] {
            let description = query["error_description"]?
                .removingPercentEncoding?
                .replacingOccurrences(of: "+", with: " ")
            throw OAuth2Error.oauth2Error(code: errorCode,
                                          description: description)
        }
        
        guard let code = query["code"] else {
            throw RedirectError.missingAuthorizationCode
        }
        
        return code
    }
}

extension AuthorizationCodeFlow: OAuth2ClientDelegate {
    
}
