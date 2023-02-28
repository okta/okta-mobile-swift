//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public protocol DirectAuthenticationFlowDelegate: AuthenticationDelegate {
    /// Sent when an authentication session receives a token.
    func authentication<Flow>(flow: Flow, received state: DirectAuthenticationFlow.State)
}

protocol DirectAuthTokenRequest {
    
}

public final class DirectAuthenticationFlow: AuthenticationFlow {
    public enum PrimaryFactor {
        case otp(code: String)
        case password(String)
        case oob(channel: Channel)
    }
    
    public enum Channel: String, Codable {
        case push
    }
    
    public struct MFAContext {
        public let supportedChallengeTypes: [GrantType]?
        let mfaToken: String
    }
    
    public enum State {
        case success(_ token: Token)
        case failure(_ error: Error)
        
        // Only needed for 2FA
        case mfaRequired(_ context: MFAContext)
    }
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    public let supportedGrantTypes: [GrantType]

    /// Any additional query string parameters you would like to supply to the authorization server.
    public let additionalParameters: [String: String]?

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
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID
    ///   - scopes: The scopes to request
    ///   - additionalParameters: Additional parameters to supply to the server.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            supportedGrants grantTypes: [GrantType] = .directAuth,
                            additionalParameters: [String: String]? = nil)
    {
        self.init(supportedGrants: grantTypes,
                  additionalParameters: additionalParameters,
                  client: .init(baseURL: issuer,
                                clientId: clientId,
                                scopes: scopes))
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(supportedGrants grantTypes: [GrantType] = .directAuth,
                additionalParameters: [String: String]? = nil,
                client: OAuth2Client)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.supportedGrantTypes = grantTypes
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Initializer that uses the configuration defined within the application's `Okta.plist` file.
    public convenience init() throws {
        try self.init(try .init())
    }
    
    /// Initializer that uses the configuration defined within the given file URL.
    /// - Parameter fileURL: File URL to a `plist` containing client configuration.
    public convenience init(plist fileURL: URL) throws {
        try self.init(try .init(plist: fileURL))
    }
    
    private convenience init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        let supportedGrantTypes: [GrantType]
        if let supportedGrants = config.additionalParameters?["supportedGrants"] {
            supportedGrantTypes = try .from(string: supportedGrants)
        } else {
            supportedGrantTypes = .directAuth
        }
        
        self.init(issuer: config.issuer,
                  clientId: config.clientId,
                  scopes: config.scopes,
                  supportedGrants: supportedGrantTypes,
                  additionalParameters: config.additionalParameters)
    }

    var stepHandler: (any StepHandler)?
    
    public func start(_ loginHint: String,
                      with factor: PrimaryFactor,
                      completion: @escaping (Result<DirectAuthenticationFlow.State, OAuth2Error>) -> Void)
    {
        isAuthenticating = true
        
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                do {
                    self.stepHandler = try factor.stepHandler(flow: self,
                                                         openIdConfiguration: configuration,
                                                         loginHint: loginHint,
                                                         factor: factor)
                    self.stepHandler?.process(completion: { result in
                        self.stepHandler = nil
                        completion(result)
                    })
                } catch {
                    self.send(error: .error(error), completion: completion)
                }
                
            case .failure(let error):
                self.send(error: error, completion: completion)
            }
        }
    }
    
    public func reset() {
        isAuthenticating = false
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<DirectAuthenticationFlowDelegate>()
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension DirectAuthenticationFlow {
    /// Asynchronously initiates an authentication flow, with an optional ``Context-swift.struct``, using Swift Concurrency.
    ///
    /// This method is used to begin an authentication session.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    /// - Returns: The URL a user should be presented with within a browser, to continue authorization.
    public func start(_ loginHint: String, with factor: PrimaryFactor) async throws -> DirectAuthenticationFlow.State {
        try await withCheckedThrowingContinuation { continuation in
            start(loginHint, with: factor) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension DirectAuthenticationFlow: UsesDelegateCollection {
    public typealias Delegate = DirectAuthenticationFlowDelegate
}

extension DirectAuthenticationFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    public func directAuthenticationFlow(supportedGrants grantTypes: [GrantType] = .directAuth,
                                         additionalParameters: [String: String]? = nil) -> DirectAuthenticationFlow
    {
        DirectAuthenticationFlow(supportedGrants: grantTypes,
                                 additionalParameters: additionalParameters,
                                 client: self)
    }
}
