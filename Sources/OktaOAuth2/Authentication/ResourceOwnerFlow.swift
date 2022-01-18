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

extension ResourceOwnerFlow: UsesDelegateCollection {
    public typealias Delegate = AuthenticationDelegate
}

extension ResourceOwnerFlow: OAuth2ClientDelegate {
    
}
