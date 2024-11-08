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
import OktaUtilities
import OktaConcurrency
import OktaConcurrency
import JWT

/// An authentication flow class that implements the JWT Authorization Bearer Flow, for authenticating users using JWTs signed by a trusted key.
@HasLock
public final class JWTAuthorizationFlow: Sendable, AuthenticationFlow, UsesDelegateCollection {
    public typealias Delegate = AuthenticationDelegate
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    /// ``JWTAuthorizationFlow/init(issuer:clientId:scopes:)``
    @Synchronized(value: false)
    public private(set) var isAuthenticating: Bool {
        didSet {
            guard oldValue != _isAuthenticating else {
                return
            }
            
            if _isAuthenticating {
                delegateCollection.invoke { $0.authenticationStarted(flow: self) }
            } else {
                delegateCollection.invoke { $0.authenticationFinished(flow: self) }
            }
        }
    }
    
    /// The collection of delegates conforming to ``AuthenticationDelegate``.
    public let delegateCollection = DelegateCollection<any Delegate>()

    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID
    ///   - scopes: The scopes to request
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String)
    {
        self.init(client: OAuth2Client(baseURL: issuer,
                                       clientId: clientId,
                                       scopes: scopes))
    }
    
    /// Initializer to construct an authentication flow from an OAuth2Client.
    /// - Parameter client: `OAuth2Client` instance to authenticate with.
    public init(client: OAuth2Client) {
        // Ensure this SDK's static version is included in the user agent.
        UserAgent.register(target: SDKVersion)

        self.client = client
        
        client.add(delegate: self)
    }
    
    /// Initializer that uses the configuration defined within the application's `Okta.plist` file.
    public convenience init() throws {
        self.init(try OAuth2Client.PropertyListConfiguration())
    }
    
    /// Initializer that uses the configuration defined within the given file URL.
    /// - Parameter fileURL: File URL to a `plist` containing client configuration.
    public convenience init(plist fileURL: URL) throws {
        self.init(try OAuth2Client.PropertyListConfiguration(plist: fileURL))
    }
    
    private convenience init(_ config: OAuth2Client.PropertyListConfiguration) {
        self.init(issuer: config.issuer,
                  clientId: config.clientId,
                  scopes: config.scopes)
    }
    
    /// Authenticates using the supplied JWT bearer assertion.
    /// - Parameters:
    ///   - assertion: JWT Assertion
    ///   - completion: Completion invoked when a response is received.
    public func start(with assertion: JWT, completion: @Sendable @escaping (Result<Token, OAuth2Error>) -> Void) {
        isAuthenticating = true

        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = TokenRequest(openIdConfiguration: configuration,
                                           clientId: self.client.configuration.clientId,
                                           scope: self.client.configuration.scopes,
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
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension JWTAuthorizationFlow {
    /// Asynchronously authenticates with a JWT bearer assertion.
    ///
    /// - Parameter jwt: JWT Assertion
    /// - Returns: The token resulting from signing in.
    public func start(with assertion: JWT) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            start(with: assertion) { result in
                continuation.resume(with: result)
            }
        }
    }
}

extension JWTAuthorizationFlow: OAuth2ClientDelegate {}

extension OAuth2Client {
    /// Creates a new JWT Authorization flow configured to use this OAuth2Client.
    /// - Returns: Initialized authorization flow.
    public func jwtAuthorizationFlow() -> JWTAuthorizationFlow {
        JWTAuthorizationFlow(client: self)
    }
}
