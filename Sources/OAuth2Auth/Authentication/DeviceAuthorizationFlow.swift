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

#if !COCOAPODS
import CommonSupport
#endif

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
    
    /// Called when a ``DeviceAuthorizationFlow/Context-swift.struct`` instance is returned from the ``DeviceAuthorizationFlow/start(with:)`` method.
    ///
    /// This context object is used to present the user with the user code, and verification URI, which will enable them to authorized the user from a different device.
    /// - Parameters:
    ///   - flow: The authentication flow that has finished.
    ///   - verification: The verification information to display to the user.
    func authentication<Flow: DeviceAuthorizationFlow>(flow: Flow, received verification: DeviceAuthorizationFlow.Verification)
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
///     issuerURL: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scope: "openid offline_access email profile")
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
public actor DeviceAuthorizationFlow: AuthenticationFlow {
    /// The OAuth2Client this authentication flow will use.
    nonisolated public let client: OAuth2Client

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    nonisolated public let additionalParameters: [String: any APIRequestArgument]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    nonisolated public var isAuthenticating: Bool {
        withIsolationSync { await self._isAuthenticating } ?? false
    }

    /// The context that stores the state for the current authentication session.
    nonisolated public var context: Context? {
        withIsolationSync { await self._context }
    }

    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID
    ///   - scope: The scopes to request
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    @inlinable
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

    @inlinable
    @_documentation(visibility: private)
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

    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - client: The `OAuth2Client` to use with this flow.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    public init(client: OAuth2Client,
                additionalParameters: [String: any APIRequestArgument]? = nil) {
        assert(SDKVersion.oauth2 != nil)

        self.client = client
        self.additionalParameters = additionalParameters

        client.add(delegate: self)
    }

    /// Initiates a device authentication flow.
    ///
    /// This method is used to begin an authentication session. The resulting ``Verification`` object can be used to display the user code and URI necessary for them to complete authentication on a different device.
    /// - Parameters:
    ///   - context: Optional context object used to customize this flow.
    public func start(with context: Context = .init()) async throws -> Verification {
        _isAuthenticating = true
        _context = context

        return try await withExpression {
            guard let url = try await client.openIdConfiguration().deviceAuthorizationEndpoint
            else {
                throw OAuth2Error.invalidUrl
            }

            let request = AuthorizeRequest(url: url,
                                           clientConfiguration: client.configuration,
                                           additionalParameters: additionalParameters,
                                           context: context)
            let response = try await request.send(to: client).result
            _context?.verification = response
            return response
        } success: { result in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: result) }
            }
        } failure: { error in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            }
            finished()
        }
    }

    /// Polls to determine when authorization completes, returning a token once it is authorized by a user out-of-band.
    ///
    /// Once an authentication session has begun, using ``start(with:)``, the user should be presented with the user code and verification URI. This method is used to poll the server, to determine when a user completes authorizing this device. At that point, the result is exchanged for a token.
    /// - Returns: The Token created as a result of exchanging an authorization code.
    public func resume() async throws -> Token {
        let client = client

        return try await withExpression {
            guard let context = _context,
                  let verification = context.verification
            else {
                throw OAuth2Error.invalidContext
            }

            let request = TokenRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                       clientConfiguration: client.configuration,
                                       additionalParameters: additionalParameters,
                                       context: context,
                                       deviceCode: verification.deviceCode)

            let taskHandle = Task {
                let poll = try APIRequestPollingHandler<TokenRequest, Token>(interval: verification.interval,
                                                                             expiresIn: verification.expiresIn,
                                                                             slowDownInterval: Self.slowDownInterval) { (_, request) in
                        .success(try await client.exchange(token: request).result)
                }
                return try await poll.start(with: request)
            }
            self.taskHandle = taskHandle

            return try await taskHandle.value
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

    /// Resets the flow for later reuse.
    public func reset() {
        finished()
        _context = nil
    }

    func finished() {
        taskHandle?.cancel()
        _isAuthenticating = false
    }

    // MARK: Private properties / methods
    static let lock = Lock()
    nonisolated(unsafe) private static var _slowDownInterval: TimeInterval = 5
    nonisolated(unsafe) static var slowDownInterval: TimeInterval {
        get {
            lock.withLock { _slowDownInterval }
        }
        set {
            lock.withLock { _slowDownInterval = newValue }
        }
    }
    static func resetToDefault() {
        slowDownInterval = 5.0
    }

    private var taskHandle: Task<Token, any Error>?
    nonisolated public let delegateCollection = DelegateCollection<any DeviceAuthorizationFlowDelegate>()

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

extension DeviceAuthorizationFlow {
    /// Asynchronously initiates a device authentication flow.
    ///
    /// This method is used to begin an authentication session. The resulting ``Verification`` object can be used to display the user code and URI necessary for them to complete authentication on a different device.
    ///
    /// - Parameters:
    ///   - context: Optional context object used to customize this flow.
    ///   - completion: Completion block for receiving the verification result which should be presented to the user.
    nonisolated public func start(with context: Context = .init(), completion: @escaping @Sendable (Result<Verification, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await start(with: context)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }

    /// Asynchronously polls to determine when authorization completes, returning a token once it is authorized by a user out-of-band.
    ///
    /// Once an authentication session has begun, using ``start(with:completion:)``, the user should be presented with the user code and verification URI. This method is used to poll the server, to determine when a user completes authorizing this device. At that point, the result is exchanged for a token.
    /// - Parameters:
    ///   - completion: Completion block for receiving the token.
    nonisolated public func resume(completion: @escaping @Sendable (Result<Token, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await resume()))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension DeviceAuthorizationFlow: UsesDelegateCollection {
    public typealias Delegate = DeviceAuthorizationFlowDelegate
}

extension DeviceAuthorizationFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    /// Creates a new Device Authorization flow configured to use this OAuth2Client.
    /// - Parameter additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    /// - Returns: Initialized authorization flow.
    public func deviceAuthorizationFlow(additionalParameters: [String: String]? = nil) -> DeviceAuthorizationFlow {
        DeviceAuthorizationFlow(client: self,
                                additionalParameters: additionalParameters)
    }
}
