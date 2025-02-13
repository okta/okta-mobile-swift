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
    public enum Audience: APIRequestArgument {
        case `default`
        case custom(String)
        
        public var stringValue: String {
            switch self {
            case .default:
                return "api://default"
            case .custom(let aud):
                return aud
            }
        }
        
        init (_ value: String?) {
            if let value = value {
                self = .custom(value)
            } else {
                self = .default
            }
        }
    }
    
    /// The OAuth2 client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The context that stores the state for the current authentication session.
    public private(set) var context: Context?

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

    /// Collection of the `AuthenticationDelegate` objects.
    public let delegateCollection = DelegateCollection<AuthenticationDelegate>()
    
    /// Convenience initializer to construct a flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scope: The scopes to request.
    ///   - audience: The audience of the authorization server.
    ///   - additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: ClaimCollection<[String]>,
                            additionalParameters: [String: APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }

    @_documentation(visibility: private)
    @inlinable
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: [String],
                            additionalParameters: [String: APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }

    @_documentation(visibility: private)
    @inlinable
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: String,
                            additionalParameters: [String: APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }

    /// Initializer to construct a flow from a default audience and client.
    /// - Parameters:
    ///   - audience: The audience of the authorization server.
    ///   - client: The `OAuth2Client` to use with this flow.
    public required init(client: OAuth2Client,
                         additionalParameters: [String: APIRequestArgument]? = nil)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Initiates a token exchange flow.
    ///
    /// This method is used to begin a token exchange.  This method is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - tokens: Tokens to exchange.
    ///   - completion: Completion block for receiving the response.
    public func start(with tokens: [TokenType],
                      context: Context = .init(),
                      completion: @escaping (Result<Token, OAuth2Error>) -> Void)
    {
        guard !tokens.isEmpty else {
            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error.cannotComposeUrl) }
            completion(.failure(OAuth2Error.cannotComposeUrl))
            
            return
        }
        
        isAuthenticating = true
        self.context = context
        let clientConfiguration = client.configuration
        let additionalParameters = additionalParameters
        
        client.openIdConfiguration { result in
            switch result {
            case .success(let openIdConfiguration):
                let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                           clientConfiguration: clientConfiguration,
                                           additionalParameters: additionalParameters,
                                           context: context,
                                           tokens: tokens)
                self.client.exchange(token: request) { result in
                    switch result {
                    case .failure(let error):
                        let oauthError = OAuth2Error.error(error)
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: oauthError) }
                        completion(.failure(oauthError))
                    case .success(let response):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                        completion(.success(response.result))
                    }
                    
                    self.isAuthenticating = false
                }
                
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                completion(.failure(error))
            }
        }
    }

    public func reset() {
        isAuthenticating = false
        context = nil
    }
}

extension TokenExchangeFlow: OAuth2ClientDelegate {
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension TokenExchangeFlow {
    /// Asynchronously initiates a token exchange flow.
    /// - Parameter tokens: Tokens to exchange. If empty, the method throws an error.
    /// - Returns: The the token created as a result of exchanging the tokens.
    public func start(with tokens: [TokenType],
                      context: Context = .init()) async throws -> Token
    {
        try await withCheckedThrowingContinuation { continuation in
            start(with: tokens, context: context) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension OAuth2Client {
    /// Creates a new Token Exchange flow configured to use this OAuth2Client, using the supplied arguments.
    /// - Parameter audience: Audience to configure the flow to use
    /// - Returns: Initialized authorization flow.
    public func tokenExchangeFlow(additionalParameters: [String: String]? = nil) -> TokenExchangeFlow
    {
        TokenExchangeFlow(client: self,
                          additionalParameters: additionalParameters)
    }
}
