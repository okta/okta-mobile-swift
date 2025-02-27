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
///     issuerURL: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scope: "openid offline_access email profile",
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
    
    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    public let additionalParameters: [String: APIRequestArgument]?

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
    public private(set) var context: Context?

    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scope: The scopes to request.
    ///   - redirectUri: The redirect URI for the client.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    @inlinable
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: ClaimCollection<[String]>,
                            redirectUri: URL,
                            additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(verifiedClient: OAuth2Client(issuerURL: issuerURL,
                                               clientId: clientId,
                                               scope: scope,
                                               redirectUri: redirectUri),
                  additionalParameters: additionalParameters)
    }
    
    @inlinable
    @_documentation(visibility: private)
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: some WhitespaceSeparated,
                            redirectUri: URL,
                            additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(verifiedClient: OAuth2Client(issuerURL: issuerURL,
                                               clientId: clientId,
                                               scope: .init(wrappedValue: scope.whitespaceSeparated),
                                               redirectUri: redirectUri),
                  additionalParameters: additionalParameters)
    }

    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - client: The `OAuth2Client` to use with this flow.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    public required convenience init(client: OAuth2Client,
                                     additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        guard client.configuration.redirectUri != nil else {
            throw OAuth2Error.missingRedirectUri
        }
     
        self.init(verifiedClient: client, additionalParameters: additionalParameters)
    }

    @usableFromInline
    init(verifiedClient client: OAuth2Client,
         additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }

    /// Initiates an authentication flow, with an optional ``Context-swift.struct``.
    ///
    /// This method is used to begin an authentication session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    /// - Returns: The URL a user should be presented with within a browser, to continue authorization.
    public func start(with context: Context = .init()) async throws -> URL {
        self.context = context
        isAuthenticating = true

        do {
            var context = context
            let url = try self.createAuthenticationURL(from: try await client.openIdConfiguration().authorizationEndpoint,
                                                       using: context)
            context.authenticationURL = url
            self.context = context

            delegateCollection.invoke { delegate in
                delegate.authentication(flow: self, shouldAuthenticateUsing: url)
            }

            return url
        } catch {
            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            finished()
            throw error
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
        do {
            guard let redirectUri = client.configuration.redirectUri else {
                throw OAuth2Error.missingRedirectUri
            }

            guard let context = self.context else {
                throw OAuth2Error.missingClientConfiguration
            }

            let code = try url.authorizationCode(redirectUri: redirectUri, state: context.state)
            let request = try TokenRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                           clientConfiguration: client.configuration,
                                           additionalParameters: additionalParameters,
                                           context: context,
                                           authorizationCode: code)
            let response = try await client.exchange(token: request)
            
            delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
            finished()
            return response.result
        } catch {
            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            finished()
            throw error
        }
    }
    
    public func reset() {
        isAuthenticating = false
        context = nil
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthorizationCodeFlowDelegate>()
}

extension AuthorizationCodeFlow {
    /// Initiates an authentication flow, with an optional ``Context-swift.struct``.
    ///
    /// This method is used to begin an authentication session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Options to customize the authentication flow.
    ///   - completion: Completion block for receiving the response.
    public func start(with context: Context = .init(),
                      completion: @escaping (Result<URL, OAuth2Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await start(with: context)))
            } catch {
                completion(.failure(OAuth2Error(error)))
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
        Task {
            do {
                completion(.success(try await resume(with: url)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension AuthorizationCodeFlow: UsesDelegateCollection {
    public typealias Delegate = AuthorizationCodeFlowDelegate
}

extension AuthorizationCodeFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    /// Creates a new Authorization Code flow configured to use this OAuth2Client.
    /// - Parameters:
    ///   - additionalParameters: Additional parameters to pass to the flow
    /// - Returns: Initialized authorization flow.
    public func authorizationCodeFlow(additionalParameters: [String: String]? = nil) throws -> AuthorizationCodeFlow
    {
        try AuthorizationCodeFlow(client: self,
                                  additionalParameters: additionalParameters)
    }
}
