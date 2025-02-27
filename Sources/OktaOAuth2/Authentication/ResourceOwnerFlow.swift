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
/// > Important: Resource Owner authentication does not support MFA or other more secure authentication models, and is not recommended for production applications. Please use the DirectAuth SDK's DirectAuthenticationFlow class instead.
public class ResourceOwnerFlow: AuthenticationFlow {
    public typealias Context = StandardAuthenticationContext
    
    /// The OAuth2Client this authentication flow will use.
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
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID
    ///   - scope: The scopes to request
    ///   - additionalParameters: Optional parameters to supply tot he authorization server for all requests from this flow.
    @inlinable
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
                            scope: some WhitespaceSeparated,
                            additionalParameters: [String: APIRequestArgument]? = nil)
    {
        self.init(client: OAuth2Client(issuerURL: issuerURL,
                                       clientId: clientId,
                                       scope: scope),
                  additionalParameters: additionalParameters)
    }

    /// Initializer that uses the predefined OAuth2Client
    /// - Parameters:
    ///   - client: ``OAuth2Client`` client instance to authenticate with.
    ///   - additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    public required init(client: OAuth2Client,
                         additionalParameters: [String: APIRequestArgument]? = nil)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Authenticates using the supplied username and password.
    /// - Parameters:
    ///   - username: Username
    ///   - password: Password
    ///   - context: Context object used to customize the flow.
    /// - Returns: The token once the responce is received.
    public func start(username: String, password: String, context: Context = .init()) async throws -> Token
    {
        isAuthenticating = true
        self.context = context

        do {
            let request = TokenRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                       clientConfiguration: client.configuration,
                                       additionalParameters: additionalParameters,
                                       context: context,
                                       username: username,
                                       password: password)
            let response = try await client.exchange(token: request)
            
            delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
            finished()
            return response.result
        } catch {
            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            finished()
            throw error
        }
    }
    
    /// Resets the flow for later reuse.
    public func reset() {
        finished()
        context = nil
    }
    
    func finished() {
        isAuthenticating = false
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthenticationDelegate>()
}

extension ResourceOwnerFlow {
    /// Authenticates using the supplied username and password.
    /// - Parameters:
    ///   - username: Username
    ///   - password: Password
    ///   - context: Context object used to customize the flow.
    ///   - completion: Completion invoked when a response is received.
    public func start(username: String,
                      password: String,
                      context: Context = .init(),
                      completion: @escaping (Result<Token, OAuth2Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await start(username: username, password: password, context: context)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension ResourceOwnerFlow: UsesDelegateCollection {
    public typealias Delegate = AuthenticationDelegate
}

extension ResourceOwnerFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    /// Creates a new Resource Owner flow configured to use this OAuth2Client.
    /// - Returns: Initialized authorization flow.
    /// - Parameter additionalParameters: Optional parameters to supply tot he authorization server for all requests from this flow.
    public func resourceOwnerFlow(additionalParameters: [String: String]? = nil) -> ResourceOwnerFlow {
        ResourceOwnerFlow(client: self, additionalParameters: additionalParameters)
    }
}
