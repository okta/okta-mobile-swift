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

#if !COCOAPODS
import CommonSupport
#endif

/// An authentication flow class that implements the Token Exchange Flow.
public actor TokenExchangeFlow: AuthenticationFlow {
    /// Identifies the audience of the authorization server.
    public enum Audience: Sendable, APIRequestArgument {
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
    nonisolated public let client: OAuth2Client

    /// The context that stores the state for the current authentication session.
    nonisolated public var context: Context? {
        withIsolationSync { await self._context }
    }

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    nonisolated public let additionalParameters: [String: any APIRequestArgument]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    nonisolated public var isAuthenticating: Bool {
        withIsolationSync { await self._isAuthenticating } ?? false
    }

    /// Collection of the `AuthenticationDelegate` objects.
    nonisolated public let delegateCollection = DelegateCollection<any AuthenticationDelegate>()

    /// Convenience initializer to construct a flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scope: The scopes to request.
    ///   - additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    public init(issuerURL: URL,
                clientId: String,
                scope: ClaimCollection<[String]>,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }

    @_documentation(visibility: private)
    @inlinable
    public init(issuerURL: URL,
                clientId: String,
                scope: some WhitespaceSeparated,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }

    /// Initializer to construct a flow from a default audience and client.
    /// - Parameters:
    ///   - client: The `OAuth2Client` to use with this flow.
    ///   - additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    public init(client: OAuth2Client,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        assert(SDKVersion.oauth2 != nil)

        self.client = client
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Asynchronously initiates a token exchange flow.
    /// - Parameters:
    ///   - tokens: Tokens to exchange. If empty, the method throws an error.
    ///   - context: Optional context used to customize the flow's behavior.
    /// - Returns: The the token created as a result of exchanging the tokens.
    public func start(with tokens: [TokenType],
                      context: Context = .init()) async throws -> Token
    {
        try await withExpression {
            guard !tokens.isEmpty else {
                await MainActor.run {
                    delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error.cannotComposeUrl) }
                }
                finished()
                throw OAuth2Error.cannotComposeUrl
            }
            
            _isAuthenticating = true
            _context = context
            
            let request = TokenRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                       clientConfiguration: client.configuration,
                                       additionalParameters: additionalParameters,
                                       context: context,
                                       tokens: tokens)
            return try await client.exchange(token: request).result
        } success: { result in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: result) }
            }
        } failure: { error in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            }
        } finally: {
            finished()
        }
    }

    public func reset() {
        finished()
        _context = nil
    }
    
    func finished() {
        _isAuthenticating = false
    }

    // MARK: Private properties / methods
    private var _context: Context?
    private var _isAuthenticating: Bool = false {
        didSet {
            guard _isAuthenticating != oldValue else {
                return
            }

            let flowStarted = _isAuthenticating
            Task { @MainActor in
                if flowStarted {
                    delegateCollection.invoke { $0.authenticationStarted(flow: self) }
                } else {
                    delegateCollection.invoke { $0.authenticationFinished(flow: self) }
                }
            }
        }
    }
}

extension TokenExchangeFlow: OAuth2ClientDelegate {
    
}

extension TokenExchangeFlow {
    /// Initiates a token exchange flow.
    /// 
    /// This method is used to begin a token exchange.  This method is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - tokens: Tokens to exchange.
    ///   - context: Optional context used to customize the flow's behavior.
    ///   - completion: Completion block for receiving the response.
    nonisolated public func start(with tokens: [TokenType],
                                  context: Context = .init(),
                                  completion: @escaping @Sendable (Result<Token, OAuth2Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await start(with: tokens, context: context)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension OAuth2Client {
    /// Creates a new Token Exchange flow configured to use this OAuth2Client, using the supplied arguments.
    /// - Parameter additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    /// - Returns: Initialized authorization flow.
    public func tokenExchangeFlow(additionalParameters: [String: String]? = nil) -> TokenExchangeFlow
    {
        TokenExchangeFlow(client: self,
                          additionalParameters: additionalParameters)
    }
}
