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

/// An authentication flow used to authenticate users using the Okta Identity Engine.
///
/// This permits a user to be authenticated using a dynamic and customizable workflow that is driven by server-side policy configuration. A user is given choices in how they authenticate, how they verify one or more authentication factors, and can enable self-service registration and authenticator enrollment.
///
/// This class is used to communicate which application, defined within Okta, the user is being authenticated with. From this point a workflow is initiated, consisting of a series of authentication ``Remediation`` steps. At each step, your application can introspect the ``Response`` object to determine which UI should be presented to your user to guide them through to login.
public final class InteractionCodeFlow: AuthenticationFlow {
    /// Options to use when initiating an ``InteractionCodeFlow``.
    public enum Option: String {
        /// Option used when a client needs to supply its own custom state value when initiating an authenticaiton flow.
        case state
        
        /// Option used when a user is authenticating using a recovery token.
        case recoveryToken = "recovery_token"

        /// Option indicating whether or not a device identifier should be sent on API requests, which enables the device to be remembered.
        case omitDeviceToken
    }
    
    /// The type used for the completion  handler result from any method that returns an ``Response``.
    /// - Parameters:
    ///   - response: The ``Response`` object that describes the next workflow steps.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias ResponseResult = (Result<Response, InteractionCodeFlowError>) -> Void

    /// The type used for the completion  handler result from any method that returns a `Token`.
    /// - Parameters:
    ///   - token: The `Token` object created when the token is successfully exchanged.
    ///   - error: Describes the error that occurred, or `nil` if the request was successful.
    public typealias TokenResult = (Result<Token, InteractionCodeFlowError>) -> Void

    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The application's redirect URI.
    public let redirectUri: URL

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

    /// The current context for the authentication session.
    ///
    /// This value is used when resuming authentication at a later date or after app launch, and to ensure the final token exchange can be completed.
    public internal(set) var context: Context?
    
    /// The options used when starting an authentication flow.
    ///
    /// This is updated when the ``start(options:completion:)`` (or ``start(options:)``) method is invoked, and is cleared when ``reset()`` is called.
    public internal(set) var options: [Option: Any]?

    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID
    ///   - scopes: The scopes to request
    ///   - redirectUri: The redirect URI for the client.
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            redirectUri: URL,
                            additionalParameters: [String: String]? = nil)
    {
        self.init(redirectUri: redirectUri,
                  additionalParameters: additionalParameters,
                  client: OAuth2Client(baseURL: issuer,
                                       clientId: clientId,
                                       scopes: scopes))
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(redirectUri: URL,
                additionalParameters: [String: String]? = nil,
                client: OAuth2Client)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)

        self.client = client
        self.redirectUri = redirectUri
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
        guard let redirectUri = config.redirectUri else {
            throw OAuth2Client.PropertyListConfigurationError.missingConfigurationValues
        }

        self.init(issuer: config.issuer,
                  clientId: config.clientId,
                  scopes: config.scopes,
                  redirectUri: redirectUri,
                  additionalParameters: config.additionalParameters)
    }
    
    /// Starts a new authentication session. If the client is able to successfully interact with Okta Identity Engine, a ``context-swift.property`` is assigned, and the initial ``Response`` is returned.
    /// - Parameters:
    ///   - options: Options to include within the OAuth2 transaction.
    ///   - completion: Completion block to be invoked when the session is started.
    public func start(options: [Option: Any]? = nil,
                      completion: @escaping ResponseResult)
    {
        if isAuthenticating {
            cancel()
        }
        
        // Ensure we have, at minimum, a state value
        let state: String = options?[.state] as? String ?? UUID().uuidString
        var options = options ?? [:]
        options[.state] = state
        
        guard let pkce = PKCE() else {
            completion(.failure(.platformUnsupported))
            return
        }
        
        self.isAuthenticating = true
        self.options = options

        let request = InteractRequest(baseURL: client.baseURL,
                                      clientId: client.configuration.clientId,
                                      scope: client.configuration.scopes,
                                      redirectUri: redirectUri,
                                      options: options,
                                      pkce: pkce)
        request.send(to: client) { result in
            switch result {
            case .failure(let error):
                self.cancel()
                self.send(error: .apiError(error), completion: completion)
            case .success(let response):
                let context = Context(interactionHandle: response.result.interactionHandle,
                                      state: state,
                                      pkce: pkce)
                self.context = context
                self.resume(completion: completion)
            }
        }
    }
    
    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method is usually performed after an ``InteractionCodeFlow`` is created in ``start(options:completion:)``, but can also be called at any time to identify what next remediation steps are available to the user.
    /// - Important:
    /// If a completion handler is not provided, you should ensure that you implement the ``InteractionCodeFlowDelegate`` methods to process any response or error returned from this call.
    /// - Parameters:
    ///   - completion: Optional completion handler invoked when a response is received.
    public func resume(completion: ResponseResult? = nil) {
        guard let context = context else {
            send(error: .invalidContext, completion: completion)
            return
        }
        
        let request: IntrospectRequest
        do {
            request = try IntrospectRequest(baseURL: client.baseURL,
                                            interactionHandle: context.interactionHandle)
        } catch let error as InteractionCodeFlowError {
            send(error: error, completion: completion)
            return
        } catch {
            send(error: .internalError(error), completion: completion)
            return
        }
        
        request.send(to: client) { result in
            switch result {
            case .failure(let error):
                self.send(error: .apiError(error),
                          completion: completion)
            case .success(let response):
                do {
                    self.send(response: try Response(flow: self, ion: response.result),
                              completion: completion)
                } catch let error as APIClientError {
                    self.send(error: .apiError(error), completion: completion)
                    return
                } catch {
                    self.send(error: .internalError(error), completion: completion)
                    return
                }
            }
        }
    }
    
    /// Evaluates the given redirect URL to determine what next steps can be performed. This is usually used when receiving a redirection from an IDP authentication flow.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    /// - Returns: Result of parsing the given redirect URL.
    public func redirectResult(for url: URL) -> RedirectResult {
        guard let context = context else {
            return .invalidContext
        }

        guard let redirect = Redirect(url: url),
              let originalRedirect = Redirect(url: redirectUri) else
        {
            return .invalidRedirectUrl
        }
        
        guard originalRedirect.scheme == redirect.scheme &&
                originalRedirect.path == redirect.path else
        {
            return .invalidRedirectUrl
        }
        
        if context.state != redirect.state {
            return .invalidContext
        }
        
        if redirect.interactionCode != nil {
            return .authenticated
        }
        
        if redirect.interactionRequired {
            return .remediationRequired
        }
        
        return .invalidContext
    }
    
    /// Exchanges the redirect URL with a token.
    ///
    /// Once the ``redirectResult(for:)`` method returns ``RedirectResult/authenticated``, the developer can exchange that redirect URL for a valid token by using this method.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    ///   - completion: Optional completion handler invoked when a token, or error, is received.
    public func exchangeCode(redirect url: URL,
                             completion: TokenResult? = nil) {
        guard let context = context else {
            send(error: .invalidContext, completion: completion)
            return
        }
        
        guard let redirect = Redirect(url: url) else {
            send(error: .internalMessage("Invalid redirect url"), completion: completion)
            return
        }
        
        guard let interactionCode = redirect.interactionCode else {
            send(error: .internalMessage("Interaction code is missed"), completion: completion)
            return
        }

        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = RedirectURLTokenRequest(openIdConfiguration: configuration,
                                                      clientId: self.client.configuration.clientId,
                                                      scope: self.client.configuration.scopes,
                                                      redirectUri: self.redirectUri.absoluteString,
                                                      interactionCode: interactionCode,
                                                      pkce: context.pkce)
                self.client.exchange(token: request) { result in
                    switch result {
                    case .success(let token):
                        self.send(response: token.result, completion: completion)
                        self.reset()
                    case .failure(let error):
                        self.send(error: .apiError(error), completion: completion)
                    }
                }
            case .failure(let error):
                self.send(error: .internalError(error), completion: completion)
            }
        }
    }
    
    /// Cancels the current authentication transaction.
    public func cancel() {
        reset()
    }
    
    /// Resets the authentication flow to its original state.
    public func reset() {
        context = nil
        isAuthenticating = false
        options = nil

        // Remove any previous `idx` cookies so it won't leak into other sessions.
        let storage = client.session.configuration.httpCookieStorage ?? HTTPCookieStorage.shared
        storage.cookies(for: client.baseURL)?
            .filter({ $0.name == "idx" })
            .forEach({ storage.deleteCookie($0) })
    }

    // MARK: Private properties / methods
    private(set) lazy var deviceTokenCookie: HTTPCookie? = {
        guard let deviceToken = InteractionCodeFlow.deviceIdentifier,
              let host = client.baseURL.host
        else {
            return nil
        }
        
        return HTTPCookie(properties: [
            .name: "DT",
            .value: deviceToken,
            .domain: host,
            .path: "/",
            .secure: "TRUE",
            .expires: Date.distantFuture,
        ])
    }()
    
    public let delegateCollection = DelegateCollection<InteractionCodeFlowDelegate>()
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension InteractionCodeFlow {
    /// Starts a new authentication session using the given configuration values. If the client is able to successfully interact with Okta Identity Engine, a new client instance is returned to the caller.
    /// - Parameters:
    ///   - configuration: Configuration describing the app settings to contact.
    ///   - options: Options to include within the OAuth2 transaction.
    /// - Returns: A ``Response``.
    public func start(options: [Option: Any]? = nil) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            start(options: options) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Resumes the authentication state to identify the available remediation steps.
    ///
    /// This method can be called at any time to identify what next remediation steps are available to the user.
    /// - Returns: A response showing the user's next steps.
    public func resume() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            resume() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Exchanges the redirect URL with a token.
    ///
    /// Once the ``redirectResult(for:)`` method returns ``RedirectResult/authenticated``, the developer can exchange that redirect URL for a valid token by using this method.
    /// - Parameters:
    ///   - url: URL with the app’s custom scheme. The value must match one of the authorized redirect URIs, which are configured in Okta Admin Console.
    public func exchangeCode(redirect url: URL) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            exchangeCode(redirect: url) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension InteractionCodeFlow: UsesDelegateCollection {
    public typealias Delegate = InteractionCodeFlowDelegate
}

extension InteractionCodeFlow: OAuth2ClientDelegate {
    public func api(client: APIClient, willSend request: inout URLRequest) {
        guard options?[.omitDeviceToken] as? Bool ?? false == false,
              let url = request.url,
              let deviceTokenCookie = deviceTokenCookie
        else {
            return
        }
        
        let storage = client.session.configuration.httpCookieStorage ?? HTTPCookieStorage.shared
        var cookies = storage.cookies(for: url) ?? []
        cookies.insert(deviceTokenCookie, at: 0)
        
        var headers = request.allHTTPHeaderFields ?? [:]
        headers.merge(HTTPCookie.requestHeaderFields(with: cookies)) { old, new in
            new
        }
        request.allHTTPHeaderFields = headers
    }
}

extension OAuth2Client {
    /// Convenience that produces an ``InteractionCodeFlow`` from an existing OAuth2Client.
    /// - Parameters:
    ///   - redirectUri: Redirect URI the client expects.
    ///   - additionalParameters: Additional parameters to supply to the authorize endpoint.
    /// - Returns: Initialized ``InteractionCodeFlow`` for this client.
    public func interactionCodeFlow(
        redirectUri: URL,
        additionalParameters: [String: String]? = nil) -> InteractionCodeFlow
    {
        InteractionCodeFlow(redirectUri: redirectUri,
                              additionalParameters: additionalParameters,
                              client: self)
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
    ///   - client: ``InteractionCodeFlow`` sending the error.
    ///   - error: The error that was received.
    func authentication<Flow: InteractionCodeFlow>(flow: Flow, received error: InteractionCodeFlowError)
    
    /// Informs the delegate when an IDX response is received, either through an ``InteractionCodeFlow/resume()`` or ``Remediation/proceed(completion:)`` call.
    /// - Parameters:
    ///   - client: ``InteractionCodeFlow`` receiving the response.
    ///   - response: The response that was received.
    func authentication<Flow: InteractionCodeFlow>(flow: Flow, received response: Response)
    
    /// Informs the delegate when authentication is successful, and the token is returned.
    /// - Parameters:
    ///   - client: ``InteractionCodeFlow`` receiving the token.
    ///   - token: The token object describing the user's credentials.
    func authentication<Flow: InteractionCodeFlow>(flow: Flow, received token: Token)
}

/// Errors reported from ``InteractionCodeFlow``.
public enum InteractionCodeFlowError: Error {
    case invalidContext
    case invalidFlow
    case platformUnsupported
    case invalidUrl
    case cannotCreateRequest
    case invalidHTTPResponse
    case invalidResponseData
    case invalidRequestData
    case serverError(message: String, localizationKey: String, type: String)
    case apiError(_: APIClientError)
    case internalError(_: Error)
    case internalMessage(_: String)
    case oauthError(summary: String, code: String?, errorId: String?)
    case invalidParameter(name: String)
    case invalidParameterValue(name: String, type: String)
    case parameterImmutable(name: String)
    case missingRequiredParameter(name: String)
    case missingRemediationOption(name: String)
    case unknownRemediationOption(name: String)
    case successResponseMissing
    case missingRefreshToken
    case missingRelatedObject
}
