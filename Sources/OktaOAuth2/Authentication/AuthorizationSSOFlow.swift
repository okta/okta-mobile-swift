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

public protocol AuthorizationSSOFlowDelegate: AuthenticationDelegate {
    
    typealias Flow = AuthorizationSSOFlow
    
    /// Called when the authorization URL has been created, indicating the URL should be presented to the user.
    /// - Parameters:
    ///   - flow: The authentication flow.
    ///   - url: The authorization URL to display in a browser to the user.
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL)
}

public class AuthorizationSSOFlow: AuthenticationFlow {
    
    public struct Configuration: AuthenticationConfiguration {
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
        
        /// The device's secret.
        public let deviceSecret: String
        
        /// The ID token.
        public let idToken: String
        
        /// Server audience.
        public let audience: Audience
    }
    
    /// A model representing the context and current state for an authorization session.
    public struct Context: Codable, Equatable {
        
        /// The current authentication URL, or `nil` if one has not yet been generated.
        internal(set) public var tokenURL: URL?
        
        /// Initializer for creating a context with a custom state string.
        public init(tokenURL: URL? = nil) {
            self.tokenURL = tokenURL
        }
    }
    
    /// The ``OAuth2Client`` this authentication flow will use.
    private(set) public var client: OAuth2Client
    
    /// The configuration used when constructing this authentication flow.
    public let configuration: Configuration
    
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
    
    /// The context for the current authentication session.
    private(set) public var context: Context? {
        didSet {
            guard let url = context?.tokenURL else {
                return
            }
            
            delegateCollection.invoke { $0.authentication(flow: self, shouldAuthenticateUsing: url) }
        }
    }
    
    public let delegateCollection = DelegateCollection<AuthorizationSSOFlowDelegate>()
    
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            deviceSecret: String,
                            idToken: String,
                            audience: Configuration.Audience) {
        self.init(Configuration(clientId: clientId,
                                scopes: scopes,
                                deviceSecret: deviceSecret,
                                idToken: idToken,
                                audience: audience),
                  client: OAuth2Client(baseURL: issuer))
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }
    
    public func start(with context: Context? = nil, completion: ((Result<URL,APIClientError>) -> Void)? = nil) {
        var context = context ?? Context()
        isAuthenticating = true
        
        client.openIdConfiguration { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                completion?(.failure(error))
                
                self.reset()
            case .success(let openIdConfiguration):
                let tokenURL = openIdConfiguration.tokenEndpoint
                
                if context.tokenURL == nil {
                    context.tokenURL = tokenURL
                }
                
                self.context = context
                
                completion?(.success(tokenURL))
            }
        }
    }
    
    public func authorize(completion: ((Result<Token,APIClientError>) -> Void)? = nil) {
        let request = TokenRequest(clientId: configuration.clientId,
                                   deviceSecret: configuration.deviceSecret,
                                   idToken: configuration.idToken,
                                   scope: configuration.scopes,
                                   audience: configuration.audience.value,
                                   tokenPath: context?.tokenURL?.path ?? "/v1/token")
        
        #warning("Temporary solution - needs to be discussed")
        if
            let tokenURL = context?.tokenURL,
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
            
            self.reset()
        }
    }
    
    public func cancel() {
    }
    
    public func reset() {
        isAuthenticating = false
        context = nil
    }
}

extension AuthorizationSSOFlow: OAuth2ClientDelegate {
    
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension AuthorizationSSOFlow {
    public func start(with context: Context? = nil) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            start(with: context) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func authorize() async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            authorize { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
