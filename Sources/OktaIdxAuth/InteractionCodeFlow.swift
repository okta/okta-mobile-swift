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
@_exported import AuthFoundation

#if !COCOAPODS
import CommonSupport
#endif

#if !COCOAPODS
import CommonSupport
#endif

/// An authentication flow used to authenticate users using the Okta Identity Engine.
///
/// This permits a user to be authenticated using a dynamic and customizable workflow that is driven by server-side policy configuration. A user is given choices in how they authenticate, how they verify one or more authentication factors, and can enable self-service registration and authenticator enrollment.
///
/// This class is used to communicate which application, defined within Okta, the user is being authenticated with. From this point a workflow is initiated, consisting of a series of authentication ``Remediation`` steps. At each step, your application can introspect the ``Response`` object to determine which UI should be presented to your user to guide them through to login.
public actor InteractionCodeFlow: AuthenticationFlow {
    /// The type used for the completion  handler result from any method that returns a `Token`.
    /// - Parameters:
    ///   - token: The `Token` object created when the token is successfully exchanged.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias TokenResult = (Result<Token, InteractionCodeFlowError>) -> Void

    /// The OAuth2Client this authentication flow will use.
    nonisolated public let client: OAuth2Client

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    nonisolated public let additionalParameters: [String: any APIRequestArgument]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    nonisolated public var isAuthenticating: Bool {
        withIsolationSync { await self._isAuthenticating } ?? false
    }

    /// The context that stores the state for the current authentication session.
    ///
    /// This value is used when resuming authentication at a later date or after app launch, and to ensure the final token exchange can be completed.
    nonisolated public var context: Context? {
        withIsolationSync { await self._context }
    }

    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scope: The scopes to request.
    ///   - redirectUri: The redirect URI for the client.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    @inlinable
    public init(issuerURL: URL,
                clientId: String,
                scope: ClaimCollection<[String]>,
                redirectUri: URL,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(verifiedClient: OAuth2Client(issuerURL: issuerURL,
                                               clientId: clientId,
                                               scope: scope,
                                               redirectUri: redirectUri),
                  additionalParameters: additionalParameters)
    }

    @inlinable
    @_documentation(visibility: private)
    public init(issuerURL: URL,
                clientId: String,
                scope: some WhitespaceSeparated,
                redirectUri: URL,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        self.init(verifiedClient: OAuth2Client(issuerURL: issuerURL,
                                               clientId: clientId,
                                               scope: .init(wrappedValue: scope.whitespaceSeparated),
                                               redirectUri: redirectUri),
                  additionalParameters: additionalParameters)
    }

    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - client: The `OAuth2Client` to use with this flow.
    ///   - additionalParameters: Optional additional query string parameters you would like to supply to the authorization server.
    public init(client: OAuth2Client,
                additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        guard client.configuration.redirectUri != nil else {
            throw OAuth2Error.redirectUriRequired
        }

        self.init(verifiedClient: client, additionalParameters: additionalParameters)
    }

    @usableFromInline
    init(verifiedClient client: OAuth2Client,
         additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        assert(SDKVersion.oktaIdx != nil)

        self.client = client
        self.additionalParameters = additionalParameters
    }

    /// Starts a new authentication session. If the client is able to successfully interact with Okta Identity Engine, a ``context-swift.property`` is assigned, and the initial ``Response`` is returned.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    /// - Returns: The URL a user should be presented with within a browser, to continue authorization.
    public func start(with context: Context = .init()) async throws -> Response {
        _context = context
        _isAuthenticating = true

        return try await withExpression {
            guard var context = _context else {
                throw OAuth2Error.invalidContext
            }

            let openIdConfiguration = try await client.openIdConfiguration()
            let interact = try await InteractRequest(openIdConfiguration: openIdConfiguration,
                                                     clientConfiguration: client.configuration,
                                                     additionalParameters: additionalParameters,
                                                     context: context)
                .send(to: client)
                .result
            context.interactionHandle = interact.interactionHandle
            _context = context

            let introspect = try await IntrospectRequest(openIdConfiguration: openIdConfiguration,
                                                         clientConfiguration: client.configuration,
                                                         additionalParameters: additionalParameters,
                                                         context: context)
                .send(to: client)
                .result

            return try Response(flow: self, ion: introspect)
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

    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method is usually performed after an ``InteractionCodeFlow`` is created in ``start(with:)``, but can also be called at any time to identify what next remediation steps are available to the user.
    public func resume() async throws -> Response {
        return try await withExpression {
            guard let context = _context else {
                throw OAuth2Error.invalidContext
            }

            let introspect = try await IntrospectRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                                         clientConfiguration: client.configuration,
                                                         additionalParameters: additionalParameters,
                                                         context: context)
                .send(to: client)
                .result

            return try Response(flow: self, ion: introspect)
        } success: { result in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: result) }
            }
        } failure: { error in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            }
        }
    }

    /// Exchanges the successful response for a token.
    ///
    /// Once the ``Response/isLoginSuccessful`` property is `true`, the developer can exchange the response for a valid token by using this method.
    public func resume(with successResponse: Response) async throws -> Token {
        return try await withExpression {
            guard let context = _context else {
                throw OAuth2Error.invalidContext
            }

            guard let remediation = successResponse.successRemediationOption,
                  remediation.name == "issue"
            else {
                throw InteractionCodeFlowError.authenticationIncomplete
            }

            guard remediation.flow === self else {
                throw InteractionCodeFlowError.invalidFlow
            }

            let openIdConfiguration = try await client.openIdConfiguration()
            let request = try InteractionCodeFlow.SuccessResponseTokenRequest(
                openIdConfiguration: openIdConfiguration,
                clientConfiguration: client.configuration,
                additionalParameters: additionalParameters,
                context: context,
                successRemediation: remediation)

            return try await request
                .send(to: client)
                .result
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

    /// Executes the given remediation option and proceeds through the workflow using the supplied form parameters.
    ///
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    public func resume(with remediation: Remediation) async throws -> Response {
        return try await withExpression {
            guard remediation.flow === self else {
                throw InteractionCodeFlowError.invalidFlow
            }

            let request = try remediation.apiRequest()
            let result = try await request.send(to: client).result
            return try Response(flow: self, ion: result)
        } success: { result in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: result) }
            }
        } failure: { error in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            }
        }
    }

    /// Resumes the authentication flow when a redirect URI is received, typically in response to a ``SocialIDPCapability`` or other redirect-based authentication factor.
    ///
    /// There are three possible outcomes when a redirect URI is received:
    ///
    /// 1. Sign in is complete.
    /// 2. The user needs to complete additional authentication steps.
    /// 3. An error was received.
    ///
    /// These different states are determined using the ``RedirectResult`` type, which indicates if a token was returned, or if a ``Response`` was produced which should be used to proceed through the sign in workflow.
    /// - Parameters:
    ///   - redirectUri: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    public func resume(with redirectUri: URL) async throws -> RedirectResult {
        // Since this function encapsulates two different behaviors, both of which need to
        // propagate error responses to the delegate collection, we are separating this workflow
        // into three steps:
        //
        // 1. Identify the result of the redirect URI's interaction code response.
        // 2. If we've received an interaction code, exchange it for tokens.
        // 3. If we need additional user interaction, return the result of `resume()`.
        //
        // This first step is wrapped in `withExpression` to ensure errors are handled
        // consistently.
        let (context, interactionResult) = try await withExpression {
            guard let clientRedirectUri = client.configuration.redirectUri else {
                throw OAuth2Error.redirectUriRequired
            }

            guard let context = _context else {
                throw OAuth2Error.invalidContext
            }

            let interactionResult = try redirectUri.interactionCode(redirectUri: clientRedirectUri,
                                                                    state: context.state)
            return (context, interactionResult)
        } failure: { error in
            Task { @MainActor in
                delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
            }
        }

        switch interactionResult {
        case .code(let interactionCode):
            // 2. Perform a token request using `withExpression` to ensure error handling is consistent.
            let token = try await withExpression {
                let request = try TokenRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                               clientConfiguration: client.configuration,
                                               additionalParameters: additionalParameters,
                                               context: context,
                                               interactionCode: interactionCode)
                return try await request.send(to: client).result
            } success: { result in
                Task { @MainActor in
                    delegateCollection.invoke { $0.authentication(flow: self, received: result) }
                }
            } failure: { error in
                Task { @MainActor in
                    delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
                }
            }
            return .success(token)
        case .interactionRequired:
            // 3. Use `resume` to create the response, but do not use `withExpression` since the
            //    `resume` function already utilizes the delegate collection properly.
            return .interactionRequired(try await self.resume())
        }
    }
    
    /// Resets the authentication flow to its original state.
    public func reset() {
        finished()
        _context = nil
    }

    func finished() {
        _isAuthenticating = false
    }

    // MARK: Private properties / methods
    @_documentation(visibility: internal)
    nonisolated public let delegateCollection = DelegateCollection<any InteractionCodeFlowDelegate>()

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

extension InteractionCodeFlow {
    /// Starts a new authentication session. If the client is able to successfully interact with Okta Identity Engine, a ``context-swift.property`` is assigned, and the initial ``Response`` is returned.
    /// - Parameters:
    ///   - context: Optional context to provide when customizing the state parameter.
    ///   - completion: Completion handler invoked when a ``Response`` is received.
    nonisolated public func start(with context: Context = .init(),
                                  completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await start(with: context)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method is usually performed after an ``InteractionCodeFlow`` is created in ``start(with:completion:)``, but can also be called at any time to identify what next remediation steps are available to the user.
    /// - Parameters:
    ///   - completion: Completion handler invoked when a ``Response`` is received.
    nonisolated public func resume(completion: @escaping @Sendable (Result<Response, any Error>) -> Void) {
        Task {
            do {
                completion(.success(try await resume()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Exchanges the successful response for a token.
    /// 
    /// Once the ``Response/isLoginSuccessful`` property is `true`, the developer can exchange the response for a valid token by using this method.
    /// - Parameters:
    ///   - successResponse: The ``Response`` object whose ``Response/isLoginSuccessful`` is `true`.
    ///   - completion: Completion handler invoked when a token, or error, is received.
    nonisolated public func resume(with successResponse: Response,
                                   completion: @escaping @Sendable (Result<Token, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await resume(with: successResponse)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Executes the given remediation option and proceeds through the workflow using the supplied form parameters.
    /// 
    /// This method is used to proceed through the authentication flow, using the data assigned to the nested fields' `value` to make selections.
    /// - Parameters:
    ///   - remediation: The individual ``Remediation`` the user has selected.
    ///   - completion: Completion handler invoked when a ``Response`` is received.
    nonisolated public func resume(with remediation: Remediation,
                                   completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await resume(with: remediation)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Resumes the authentication flow when a redirect URI is received, typically in response to a ``SocialIDPCapability`` or other redirect-based authentication factor.
    ///
    /// There are three possible outcomes when a redirect URI is received:
    ///
    /// 1. Sign in is complete.
    /// 2. The user needs to complete additional authentication steps.
    /// 3. An error was received.
    ///
    /// These different states are determined using the ``RedirectResult`` type, which indicates if a token was returned, or if a ``Response`` was produced which should be used to proceed through the sign in workflow.
    /// - Parameters:
    ///   - redirectUri: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    ///   - completion: Completion handler invoked when a response is received.
    nonisolated public func resume(with redirectUri: URL,
                                   completion: @escaping @Sendable (Result<RedirectResult, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await resume(with: redirectUri)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension InteractionCodeFlow: UsesDelegateCollection {
    public typealias Delegate = InteractionCodeFlowDelegate
}

extension OAuth2Client {
    /// Convenience that produces an ``InteractionCodeFlow`` from an existing OAuth2Client.
    /// - Parameters:
    ///   - additionalParameters: Additional parameters to supply to the authorize endpoint.
    /// - Returns: Initialized ``InteractionCodeFlow`` for this client.
    public func interactionCodeFlow(additionalParameters: [String: String]? = nil) throws -> InteractionCodeFlow
    {
        try InteractionCodeFlow(client: self,
                                additionalParameters: additionalParameters)
    }
}

/// Delegate protocol that can be used to receive updates from the ``InteractionCodeFlow`` through the process of a user's authentication.
public protocol InteractionCodeFlowDelegate: AuthenticationDelegate {
    /// Called before authentication begins.
    /// - Parameters:
    ///   - flow: The authentication flow that has started.
    func authenticationStarted<Flow: InteractionCodeFlow>(flow: Flow)

    /// Called after authentication completes.
    /// - Parameters:
    ///   - flow: The authentication flow that has finished.
    func authenticationFinished<Flow: InteractionCodeFlow>(flow: Flow)

    /// Message sent when an error is received at any point during the authentication process.
    /// - Parameters:
    ///   - flow: The ``InteractionCodeFlow`` sending the error.
    ///   - error: The error that was received.
    func authentication<Flow: InteractionCodeFlow>(flow: Flow, received error: InteractionCodeFlowError)
    
    /// Informs the delegate when an IDX response is received, either through an ``InteractionCodeFlow/resume()`` or ``Remediation/proceed(completion:)`` call.
    /// - Parameters:
    ///   - flow: The ``InteractionCodeFlow`` receiving the response.
    ///   - response: The response that was received.
    func authentication<Flow: InteractionCodeFlow>(flow: Flow, received response: Response)
    
    /// Informs the delegate when authentication is successful, and the token is returned.
    /// - Parameters:
    ///   - flow: The ``InteractionCodeFlow`` receiving the token.
    ///   - token: The token object describing the user's credentials.
    func authentication<Flow: InteractionCodeFlow>(flow: Flow, received token: Token)
}

/// Errors reported from ``InteractionCodeFlow``.
public enum InteractionCodeFlowError: Error {
    case invalidFlow
    case authenticationIncomplete
    case invalidParameter(name: String)
    case missingRequiredParameter(name: String)
    case missingRemediation(name: String)
    case responseValidationFailed(_ message: String)
}
