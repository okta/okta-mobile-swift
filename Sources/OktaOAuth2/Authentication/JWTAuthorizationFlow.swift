//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// An authentication flow class that implements the JWT Authorization Bearer Flow, for authenticating users using JWTs signed by a trusted key.
public class JWTAuthorizationFlow: AuthenticationFlow {
    public typealias Context = StandardAuthenticationContext
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The context that stores the state for the current authentication session.
    public private(set) var context: Context?

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    public let additionalParameters: [String: APIRequestArgument]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    /// ``JWTAuthorizationFlow/init(issuerURL:clientId:scope:additionalParameters:)``
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
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID
    ///   - scope: The scopes to request
    ///   - additionalParameters: Additional parameters to add to all requests made by this flow.
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: String,
                            additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }
    
    /// Initializer to construct an authentication flow from an OAuth2Client.
    /// - Parameters:
    ///   - client: OAuth2Client to use.
    ///   - additionalParameters: Additional parameters to add to all requests made by this flow.
    public required init(client: OAuth2Client,
                         additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Authenticates using the supplied JWT bearer assertion.
    /// - Parameters:
    ///   - assertion: JWT Assertion
    ///   - context: Context used to customize the flow.
    ///   - completion: Completion invoked when a response is received.
    public func start(with assertion: JWT,
                      context: Context = .init(),
                      completion: @escaping (Result<Token, OAuth2Error>) -> Void)
    {
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
                                           assertion: assertion)
                self.client.exchange(token: request) { result in
                    self.reset()
                    
                    switch result {
                    case .failure(let error):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                        completion(.failure(.network(error: error)))
                    case .success(let response):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                        completion(.success(response.result))
                    }
                }

            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                completion(.failure(error))
            }
        }
    }
    
    /// Resets the flow for later reuse.
    public func reset() {
        isAuthenticating = false
        context = nil
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthenticationDelegate>()
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension JWTAuthorizationFlow {
    /// Asynchronously authenticates with a JWT bearer assertion.
    /// 
    /// - Parameters:
    ///   - assertion: JWT Assertion
    ///   - context: Context used to customize the flow.
    /// - Returns: The token resulting from signing in.
    public func start(with assertion: JWT, context: Context = .init()) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            start(with: assertion, context: context) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension JWTAuthorizationFlow: UsesDelegateCollection {
    public typealias Delegate = AuthenticationDelegate
}

extension JWTAuthorizationFlow: OAuth2ClientDelegate {}

extension OAuth2Client {
    /// Creates a new JWT Authorization flow configured to use this OAuth2Client.
    /// - Parameter additionalParameters: Additional parameters to supply to requests from this flow.
    /// - Returns: Initialized authorization flow.
    public func jwtAuthorizationFlow(additionalParameters: [String: String]? = nil) -> JWTAuthorizationFlow {
        JWTAuthorizationFlow(client: self, additionalParameters: additionalParameters)
    }
}
