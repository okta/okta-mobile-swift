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

/// An authentication flow class that implements the Token Exchange Flow.
public class TokenExchangeFlow: AuthenticationFlow {
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
    
    /// The OAuth2 client this authentication flow will use.
    public let client: OAuth2Client
    
    /// Server audience.
    public let audience: Audience

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

    /// Collection of the `AuthenticationDelegate` objects.
    public let delegateCollection = DelegateCollection<AuthenticationDelegate>()
    
    /// Convenience initializer to construct a flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scopes: The scopes to request.
    ///   - audience: The audience of the authorization server.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            audience: Audience = .default) {
        self.init(audience: audience,
                  client: OAuth2Client(baseURL: issuer,
                                       clientId: clientId,
                                       scopes: scopes))
    }
    
    /// Initializer to construct a flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(audience: Audience = .default, client: OAuth2Client) {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.audience = audience
        
        client.add(delegate: self)
    }

    /// Initiates a token exchange flow.
    ///
    /// This method is used to begin a token exchange.  This method is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - tokens: Tokens to exchange.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func resume(with tokens: [TokenType], completion: ((Result<Token, OAuth2Error>) -> Void)? = nil) {
        guard !tokens.isEmpty else {
            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error.cannotComposeUrl) }
            completion?(.failure(OAuth2Error.cannotComposeUrl))
            
            return
        }
        
        isAuthenticating = true
        
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = TokenRequest(openIdConfiguration: configuration,
                                           clientId: self.client.configuration.clientId,
                                           tokens: tokens,
                                           scope: self.client.configuration.scopes,
                                           audience: self.audience.value)
                self.client.exchange(token: request) { result in
                    switch result {
                    case .failure(let error):
                        let oauthError = OAuth2Error.error(error)
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: oauthError) }
                        completion?(.failure(oauthError))
                    case .success(let response):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                        completion?(.success(response.result))
                    }
                    
                    self.isAuthenticating = false
                }
                
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
            }
        }
    }

    /// Cancel an initiated token exchange flow.
    public func cancel() {
    }
    
    public func reset() {
        
    }
}

extension TokenExchangeFlow: OAuth2ClientDelegate {
    
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension TokenExchangeFlow {
    /// Asynchronously initiates a token exchange flow.
    /// - Parameter tokens: Tokens to exchange. If empty, the method throws an error.
    /// - Returns: The the token created as a result of exchanging the tokens.
    public func resume(with tokens: [TokenType]) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            resume(with: tokens) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension OAuth2Client {
    public func tokenExchangeFlow(audience: TokenExchangeFlow.Audience = .default) -> TokenExchangeFlow {
        TokenExchangeFlow(audience: audience, client: self)
    }
}
