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

/// An authentication flow class that implements the Resource Owner Flow exchange.
///
/// This simple authentication flow permits a suer to authenticate using a simple username and password. As such, the configuration is straightforward.
///
/// > Important: Resource Owner authentication does not support MFA or other more secure authentication models, and is not recommended for production applications.
@available(*, deprecated, message: "Please use the DirectAuth SDK's DirectAuthenticationFlow class instead")
public class ResourceOwnerFlow: AuthenticationFlow {
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    /// ``ResourceOwnerFlow/init(issuer:clientId:scopes:)``
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
    
    public init(client: OAuth2Client) {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
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
    
    /// Authenticates using the supplied username and password.
    /// - Parameters:
    ///   - username: Username
    ///   - password: Password
    ///   - completion: Completion invoked when a response is received.
    public func start(username: String, password: String, completion: @escaping (Result<Token, OAuth2Error>) -> Void) {
        isAuthenticating = true

        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = TokenRequest(openIdConfiguration: configuration,
                                           clientId: self.client.configuration.clientId,
                                           scope: self.client.configuration.scopes,
                                           username: username,
                                           password: password)
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

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthenticationDelegate>()
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension ResourceOwnerFlow {
    /// Asynchronously authenticates with the Resource Owner flow.
    ///
    /// - Returns: The information a user should be presented with to continue authorization on a different device.
    public func start(username: String, password: String) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            start(username: username, password: password) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension ResourceOwnerFlow: UsesDelegateCollection {
    public typealias Delegate = AuthenticationDelegate
}

extension ResourceOwnerFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    public func resourceOwnerFlow() -> ResourceOwnerFlow {
        ResourceOwnerFlow(client: self)
    }
}
