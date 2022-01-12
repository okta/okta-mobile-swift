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

import AuthFoundation
import Foundation

/// The delegate of a ``TokenExchangeFlow`` may adopt some, or all, of the methods described here. These allow a developer to customize or interact with the  flow during authentication.
///
/// This protocol extends the basic ``AuthenticationDelegate`` which all authentication flows support.
public protocol TokenExchangeFlowDelegate: AuthenticationDelegate {
    
    typealias Flow = TokenExchangeFlow
    
    /// Called when the authorization URL has been created, indicating the URL should be used for token exchange.
    /// - Parameters:
    ///   - flow: The authentication flow.
    ///   - url: The URL for token exchange.
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL)
}


/// An authentication flow class that implements the Token Exchange Flow.
///
/// The Token Exchange Flow allows a client to get the Access Token exchanging other tokens. As an example, consider [SSO for Native Apps](https://developer.okta.com/docs/guides/configure-native-sso/main/#native-sso-flow) where a client exchanges the ID and the Device Secret tokens to get the access to the resource.
///
/// You can create an instance of  ``TokenExchangeFlow/Configuration-swift.struct`` to define your client's settings, and supply that to the initializer, along with a reference to your ``OAuth2Client`` for performing key operations and requests. Alternatively, you can use any of the convenience initializers to simplify the process.
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``AuthorizationCodeFlow`` can just as easily be used with completion blocks or through the use of the ``AuthorizationCodeFlowDelegate``.
///
/// ```swift
/// let flow = TokenExchangeFlow(
///     issuer: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scopes: "openid offline_access email profile",
///     audience: .default)
///
/// let tokens: [TokenType] = [
///     .actor(type: .deviceSecret, value: "DeviceToken"),
///     .subject(type: .idToken, value: "IDToken")
/// ]
/// let token = try await flow.resume(with: tokens)
/// ```
public class TokenExchangeFlow: AuthenticationFlow {
    /// Configuration settings that define the OAuth2 client to be authenticated against.
    public struct Configuration: AuthenticationConfiguration {
        /// Identifies the audience of the authorization server.
        public enum Audience {
            case `default`
            case custom(String)
            
            var value: String {
                switch self {
                case .default:
                    return "api://default"
                case .custom(let aud):
                    return aud
                }
            }
        }
        
        /// The client's ID.
        public let clientId: String
        
        /// The scopes requested.
        public let scopes: String
        
        /// Server audience.
        public let audience: Audience
    }
    
    /// The ``OAuth2Client`` this authentication flow will use.
    private(set) public var client: OAuth2Client
    
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

    /// Collection of the ``TokenExchangeFlowDelegate`` objects.
    public let delegateCollection = DelegateCollection<TokenExchangeFlowDelegate>()
    
    /// Convenience initializer to construct a flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scopes: The scopes to request.
    ///   - audience: The audience of the authorization server.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            audience: Configuration.Audience) {
        self.init(Configuration(clientId: clientId,
                                scopes: scopes,
                                audience: audience),
                  client: OAuth2Client(baseURL: issuer))
    }
    
    /// Initializer to construct a flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }

    /// Initiates a token exchange flow.
    ///
    /// This method is used to begin a token exchange.  This method is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - tokens: Tokens to exchange.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func resume(with tokens: [TokenType], completion: ((Result<Token,APIClientError>) -> Void)? = nil) {
        if tokens.isEmpty {
            delegateCollection.invoke { $0.authentication(flow: self, received: .flowNotReady(message: "Array of tokens is empty.")) }
            completion?(.failure(.invalidRequestData))
            
            return
        }
        
        isAuthenticating = true
        
        client.openIdConfiguration { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                completion?(.failure(error))
                
                self.isAuthenticating = false
            case .success(let openIdConfiguration):
                self.delegateCollection.invoke { $0.authentication(flow: self, shouldAuthenticateUsing: openIdConfiguration.tokenEndpoint) }
                self.authenticate(tokenURL: openIdConfiguration.tokenEndpoint, tokens: tokens, completion: completion)
            }
        }
    }

    /// Cancel an initiated token exchange flow.
    public func cancel() {
    }
    
    public func reset() {
        
    }
    
    private func authenticate(tokenURL: URL, tokens: [TokenType], completion: ((Result<Token,APIClientError>) -> Void)? = nil) {
        let request = TokenRequest(clientId: configuration.clientId,
                                   tokens: tokens,
                                   scope: configuration.scopes,
                                   audience: configuration.audience.value,
                                   tokenPath: tokenURL.path)
        if
            let tokenBaseURL = URL(string: tokenURL.absoluteString.replacingOccurrences(of: tokenURL.path, with: "")),
            tokenBaseURL != client.baseURL
        {
            client = OAuth2Client(baseURL: tokenBaseURL, session: client.session)
        }
        
        client.exchange(token: request) { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                completion?(.failure(error))
            case .success(let response):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                completion?(.success(response.result))
            }
            
            self.isAuthenticating = false
        }
    }
}

extension TokenExchangeFlow: OAuth2ClientDelegate {
    
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension TokenExchangeFlow {
    /// Asynchronously initiates a token exchange flow.
    /// - Parameter tokens: Tokens to exchange. If empty, the method throws an error.
    /// - Returns: The ``Token`` created as a result of exchanging the tokens.
    public func resume(with tokens: [TokenType]) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            resume(with: tokens) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
