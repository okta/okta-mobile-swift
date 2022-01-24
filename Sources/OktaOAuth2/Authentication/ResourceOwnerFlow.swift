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
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily.
///
/// ```swift
/// let flow = ResourceOwnerFlow(
///     issuer: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scopes: "openid offline_access email profile")
///
/// // Authenticate with a username and password.
/// let token = try await flow.resume(username: "smeagol", password: "myprecious")
/// ```
public class ResourceOwnerFlow: AuthenticationFlow {
    public typealias AuthConfiguration = ResourceOwnerFlow.Configuration
    
    public struct Configuration: AuthenticationConfiguration {
        /// The client's ID.
        public let clientId: String
        
        /// The scopes requested.
        public let scopes: String
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
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID
    ///   - scopes: The scopes to request
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String)
    {
        self.init(Configuration(clientId: clientId,
                                scopes: scopes),
                  client: OAuth2Client(baseURL: issuer))
    }
    
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }
    
    /// Authenticates using the supplied username and password.
    /// - Parameters:
    ///   - username: Username
    ///   - password: Password
    ///   - completion: Completion invoked when a response is received.
    public func resume(username: String, password: String, completion: ((Result<Token,APIClientError>) -> Void)? = nil) {
        isAuthenticating = true

        let request = TokenRequest(clientId: configuration.clientId,
                                   scope: configuration.scopes,
                                   username: username,
                                   password: password)
        client.exchange(token: request) { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                completion?(.failure(error))
            case .success(let response):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                completion?(.success(response.result))
            }
            
            self.reset()
            self.isAuthenticating = false
        }
    }
    
    /// Cancels the current authorization session.
    public func cancel() {
        reset()
    }
    
    /// Resets the flow for later reuse.
    public func reset() {
        isAuthenticating = false
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthenticationDelegate>()
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension ResourceOwnerFlow {
    /// Asynchronously authenticates with the Resource Owner flow.
    ///
    /// - Returns: The information a user should be presented with to continue authorization on a different device.
    public func resume(username: String, password: String) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            resume(username: username, password: password) { result in
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
