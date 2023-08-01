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

/// The delegate of ``DeviceAuthorizationFlow`` may adopt some, or all, of the methods described here. These allow a developer to customize or interact with the authentication flow during authentication.
///
/// This protocol extends the basic `AuthenticationDelegate` which all authentication flows support.
public protocol DeviceAuthorizationFlowDelegate: AuthenticationDelegate {
    /// Called before authentication begins.
    /// - Parameters:
    ///   - flow: The authentication flow that has started.
    func authenticationStarted<Flow: DeviceAuthorizationFlow>(flow: Flow)

    /// Called after authentication completes.
    /// - Parameters:
    ///   - flow: The authentication flow that has finished.
    func authenticationFinished<Flow: DeviceAuthorizationFlow>(flow: Flow)
    
    /// Called when a ``DeviceAuthorizationFlow/Context-swift.struct`` instance is returned from the ``DeviceAuthorizationFlow/start(completion:)`` method.
    ///
    /// This context object is used to present the user with the user code, and verification URI, which will enable them to authorized the user from a different device.
    /// - Parameters:
    ///   - flow: The authentication flow that has finished.
    ///   - context: The context to display to the user.
    func authentication<Flow: DeviceAuthorizationFlow>(flow: Flow, received context: DeviceAuthorizationFlow.Context)
}

/// An authentication flow class that implements the Device Authorization Grant flow exchange.
///
/// The Device Authorization Grant flow permits a user to sign in securely from a headless or other similar device (e.g. set-top boxes, Smart TVs, or other devices with limited keyboard input). Using this flow, a user is presented with a screen that provides two pieces of information:
/// 1. A URL the user should visit from another device.
/// 2. A simple user code they can easily enter on that secondary device.
///
/// Upon visiting that URL and entering in the code, the user is prompted to sign in using their standard credentials. Upon completing authentication, the device automatically signs the user in, without any direct interaction on the user's part.
///
/// You can create an instance of  ``DeviceAuthorizationFlow`` with your client's settings, and supply that to the initializer, along with a reference to your OAuth2Client for performing key operations and requests. Alternatively, you can use any of the convenience initializers to simplify the process.
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``DeviceAuthorizationFlow`` can just as easily be used with completion blocks or through the use of the ``DeviceAuthorizationFlowDelegate``.
///
/// ```swift
/// let flow = DeviceAuthorizationFlow(
///     issuer: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scopes: "openid offline_access email profile")
///
/// // Retrieve the context for this session.
/// let context = try await flow.start()
///
/// // Present the userCode and verificationUri from the context
/// // to the user. Once that is done, use the following code to
/// // poll the server to retrieve a token when they authorize
/// // the code.
/// let token = try await flow.resume(with: context)
/// ```
public class DeviceAuthorizationFlow: AuthenticationFlow {
    /// A model representing the context and current state for an authorization session.
    public struct Context: Decodable, Equatable, Expires {
        let deviceCode: String
        var interval: TimeInterval
        
        /// The date this context was created.
        public let issuedAt: Date?

        /// The code that should be displayed to the user.
        public let userCode: String
        
        /// The URI the user should be prompted to open in order to authorize the application.
        public let verificationUri: URL
        
        /// A convenience URI that combines the ``verificationUri`` and the ``userCode``, to make a clickable link.
        public let verificationUriComplete: URL?
        
        /// The time interval after which the authorization context will expire.
        public let expiresIn: TimeInterval
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case issuedAt
            case userCode
            case verificationUri
            case verificationUriComplete
            case expiresIn
            case deviceCode
            case interval
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            issuedAt = try container.decodeIfPresent(Date.self, forKey: .issuedAt) ?? Date()
            deviceCode = try container.decode(String.self, forKey: .deviceCode)
            userCode = try container.decode(String.self, forKey: .userCode)
            verificationUri = try container.decode(URL.self, forKey: .verificationUri)
            verificationUriComplete = try container.decodeIfPresent(URL.self, forKey: .verificationUriComplete)
            expiresIn = try container.decode(TimeInterval.self, forKey: .expiresIn)
            interval = try container.decodeIfPresent(TimeInterval.self, forKey: .interval) ?? 5.0
        }
    }
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
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
    
    /// The context that stores the state for the current authentication session.
    public private(set) var context: Context? {
        didSet {
            guard let context = context else {
                return
            }

            delegateCollection.invoke { $0.authentication(flow: self, received: context) }
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
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
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
    
    /// Initiates a device authentication flow.
    ///
    /// This method is used to begin an authentication session. The resulting ``Context-swift.struct`` object can be used to display the user code and URI necessary for them to complete authentication on a different device.
    ///
    /// The ``resume(with:completion:)`` method also uses this context, to poll the server to determine when the user approves the authorization request.
    /// - Parameters:
    ///   - completion: Completion block for receiving the context.
    public func start(completion: @escaping (Result<Context, OAuth2Error>) -> Void) {
        isAuthenticating = true

        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                guard let url = configuration.deviceAuthorizationEndpoint else {
                    self.delegateCollection.invoke { $0.authentication(flow: self, received: .invalidUrl) }
                    completion(.failure(.invalidUrl))
                    return
                }
                
                let request = AuthorizeRequest(url: url,
                                               clientId: self.client.configuration.clientId,
                                               scope: self.client.configuration.scopes)
                request.send(to: self.client) { result in
                    switch result {
                    case .failure(let error):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                        completion(.failure(.network(error: error)))
                    case .success(let response):
                        self.context = response.result
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
    
    /// Polls to determine when authorization completes, using the supplied ``Context-swift.struct`` instance.
    ///
    /// Once an authentication session has begun, using ``start(completion:)``, the user should be presented with the user code and verification URI. This method is used to poll the server, to determine when a user completes authorizing this device. At that point, the result is exchanged for a token.
    /// - Parameters:
    ///   - context: Device authorization context object.
    ///   - completion: Completion block for receiving the token.
    public func resume(with context: Context, completion: @escaping (Result<Token, OAuth2Error>) -> Void) {
        self.completion = completion
        scheduleTimer()
    }
    
    /// Resets the flow for later reuse.
    public func reset() {
        timer?.cancel()
        timer = nil
        context = nil
        completion = nil
        isAuthenticating = false
    }

    // MARK: Private properties / methods
    static var slowDownInterval: TimeInterval = 5
    
    var timer: DispatchSourceTimer?
    var completion: ((Result<Token, OAuth2Error>) -> Void)?
    public let delegateCollection = DelegateCollection<DeviceAuthorizationFlowDelegate>()
    
    func scheduleTimer(offsetBy interval: TimeInterval? = nil) {
        guard var context = context else {
            return
        }
        
        if let interval = interval {
            context.interval += interval
            self.context = context
        }
        
        let completion = self.completion
        
        let timerSource = DispatchSource.makeTimerSource()
        timerSource.schedule(deadline: .now() + context.interval, repeating: context.interval)
        timerSource.setEventHandler {
            self.getToken(using: context) { result in
                switch result {
                case .failure(let error):
                    self.reset()
                    completion?(.failure(.network(error: error)))
                    
                case .success(let token):
                    if let token = token {
                        self.reset()
                        completion?(.success(token))
                    }
                }
            }
        }

        timer?.cancel()
        timer = timerSource
        timerSource.resume()
    }
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension DeviceAuthorizationFlow {
    /// Asynchronously initiates a device authentication flow.
    ///
    /// This method is used to begin an authentication session. The resulting ``Context-swift.struct`` object can be used to display the user code and URI necessary for them to complete authentication on a different device.
    ///
    /// The ``resume(with:)`` method also uses this context, to poll the server to determine when the user approves the authorization request.
    /// - Returns: The information a user should be presented with to continue authorization on a different device.
    public func start() async throws -> Context {
        try await withCheckedThrowingContinuation { continuation in
            start { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Asynchronously polls to determine when authorization completes, using the supplied ``Context-swift.struct`` instance.
    ///
    /// Once an authentication session has begun, using ``start()``, the user should be presented with the user code and verification URI. This method is used to poll the server, to determine when a user completes authorizing this device. At that point, the result is exchanged for a token.
    /// - Parameters:
    ///   - context: Device authorization context object.
    /// - Returns: The Token created as a result of exchanging an authorization code.
    public func resume(with context: Context) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            resume(with: context) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension DeviceAuthorizationFlow: UsesDelegateCollection {
    public typealias Delegate = DeviceAuthorizationFlowDelegate
}

extension DeviceAuthorizationFlow {
    func getToken(using context: Context, completion: @escaping(Result<Token?, APIClientError>) -> Void) {
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = TokenRequest(openIdConfiguration: configuration,
                                           clientId: self.client.configuration.clientId,
                                           deviceCode: context.deviceCode)
                self.client.exchange(token: request) { result in
                    switch result {
                    case .failure(let error):
                        if case let APIClientError.serverError(serverError) = error,
                           let oauthError = serverError as? OAuth2ServerError
                        {
                            switch oauthError.code {
                            case .authorizationPending:
                                // Keep polling, since we haven't received a token yet.
                                completion(.success(nil))
                                return
                                
                            case .slowDown:
                                // Increase the polling interval for all subsequent requests, according to the specification.
                                self.scheduleTimer(offsetBy: DeviceAuthorizationFlow.slowDownInterval)
                                completion(.success(nil))
                                return
                                
                            default: break
                            }
                        }

                        self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
                        completion(.failure(error))
                    case .success(let response):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
                        completion(.success(response.result))
                    }
                }
                
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
            }
        }
    }
}

extension DeviceAuthorizationFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    public func deviceAuthorizationFlow() -> DeviceAuthorizationFlow {
        DeviceAuthorizationFlow(client: self)
    }
}
