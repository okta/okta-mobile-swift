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

#if !COCOAPODS
import CommonSupport
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Delegate protocol used by ``OAuth2Client`` to communicate important events.
public protocol OAuth2ClientDelegate: AnyObject, APIClientDelegate {
    /// Sent before a token will begin to refresh.
    func oauth(client: OAuth2Client, willRefresh token: Token)

    /// Sent when a token has finished refreshing.
    func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?)
}

extension OAuth2ClientDelegate {
    public func oauth(client: OAuth2Client, willRefresh token: Token) {}
    public func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {}
}

// swiftlint:disable type_body_length
/// An OAuth2 client, used to interact with a given authorization server.
public final class OAuth2Client: UsesDelegateCollection {
    public typealias Delegate = OAuth2ClientDelegate
    
    /// Defines the default URLSession instance used when initializing a new ``OAuth2Client``.
    ///
    /// This is used by any class that needs to perform network operations and needs an instance of `URLSession` to be able to do so. If this value is `nil`, the behavior is to create a new instance as necessary. Assign a value to this property if you want to explicitly use your own session.
    ///
    /// > Important: This value only overrides the default session, and will not supercede any explicitly-assigned value supplied to the initializer, such as ``OAuth2Client/init(_:session:)``.
    public static var defaultSession: (any URLSessionProtocol)? {
        get { lock.withLock { _defaultSession } }
        set { lock.withLock { _defaultSession = newValue } }
    }

    /// The URLSession used by this client for network requests.
    public let session: any URLSessionProtocol
    
    /// The configuration that identifies this OAuth2 client.
    public let configuration: Configuration
    
    /// Additional HTTP headers to include in outgoing network requests.
    nonisolated public var additionalHttpHeaders: [String: String]? {
        get {
            lock.withLock {
                _additionalHttpHeaders
            }
        }
        set {
            lock.withLock {
                _additionalHttpHeaders = newValue
            }
        }
    }

    /// The OpenID configuration for this org.
    ///
    /// This value will be `nil` until the configuration has been retrieved through the ``openIdConfiguration(completion:)`` or ``openIdConfiguration()`` functions.
    public var openIdConfiguration: OpenIdConfiguration? {
        openIdConfigurationAction.value
    }

    /// The ``JWKS`` key set for this org.
    ///
    /// This value will be `nil` until the keys have been retrieved through the ``jwks(completion:)`` or ``jwks()`` functions.
    public var jwks: JWKS? {
        jwksAction.value
    }

    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - issuerURL: The issuer URL for operations against this client.
    ///   - clientId: The unique client ID representing this client.
    ///   - scope: The list of OAuth2 scopes requested for this client.
    ///   - redirectUri: Optional `redirect_uri` value for this client.
    ///   - logoutRedirectUri: Optional `logout_redirect_uri` value for this client.
    ///   - authentication: The client authentication  model to use (Default: `.none`)
    ///   - session: Optional URLSession to use for network requests.
    @inlinable
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: ClaimCollection<[String]>,
                            redirectUri: URL? = nil,
                            logoutRedirectUri: URL? = nil,
                            authentication: ClientAuthentication = .none,
                            session: (any URLSessionProtocol)? = nil)
    {
        self.init(Configuration(issuerURL: issuerURL,
                                clientId: clientId,
                                scope: scope,
                                redirectUri: redirectUri,
                                logoutRedirectUri: logoutRedirectUri,
                                authentication: authentication),
                  session: session)
    }
    
    /// Constructs an OAuth2Client for the given base URL.
    /// - Parameters:
    ///   - configuration: The pre-formed configuration for this client.
    ///   - session: Optional URLSession to use for network requests.
    public init(_ configuration: Configuration, session: (any URLSessionProtocol)? = nil) {
        assert(SDKVersion.authFoundation != nil)

        // Ensure the time coordinator is properly initialized
        _ = Date.coordinator
        
        self.configuration = configuration
        self.session = session ?? Self.defaultSession ?? URLSession(configuration: .ephemeral)
        self.refreshQueue = DispatchQueue(label: "com.okta.refreshQueue.\(configuration.issuerURL.host ?? "unknown")",
                                          qos: .userInitiated,
                                          attributes: .concurrent)

        Task { @MainActor in
            TaskData.notificationCenter.post(name: .oauth2ClientCreated, object: self)
        }

        // Ensure the Credential Coordinator can monitor this client for token refresh changes.
        TaskData.coordinator.observe(oauth2: self)
    }
    
    /// Retrieves the org's OpenID configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Returns: The OpenID configuration for the org identified by the client's base URL.
    public func openIdConfiguration() async throws -> OpenIdConfiguration {
        try await openIdConfigurationAction.perform {
            try await OpenIdConfigurationRequest(url: configuration.discoveryURL)
                .send(to: self)
                .result
        }
    }
    
    /// Attempts to refresh the supplied token, using the ``Token/refreshToken`` if it is available.
    ///
    /// This method prevents multiple concurrent refresh requests to be performed for a given token, though all applicable results will be returned once the token refresh has completed.
    /// - Parameters:
    ///   - token: Token to refresh.
    ///   - scope: Optional array of scopes to request.
    public func refresh(_ token: Token, scope: [String]? = nil) async throws -> Token {
        try await token.refreshAction.perform(reset: true) {
            guard let refreshToken = token.refreshToken else {
                throw OAuth2Error.missingToken(type: .refreshToken)
            }
            
            let request = Token.RefreshRequest(openIdConfiguration: try await openIdConfiguration(),
                                               clientConfiguration: configuration,
                                               refreshToken: refreshToken,
                                               scope: scope?.joined(separator: " "),
                                               id: token.id)
            async let response = try request.send(to: self)

            return try await response.result.token(merging: token)
        } willBegin: {
            delegateCollection.invoke { $0.oauth(client: self, willRefresh: token) }
        } didEnd: { result in
            let newToken: Token?
            switch result {
            case .success(let token):
                TaskData.notificationCenter.post(name: .tokenRefreshed, object: token)
                newToken = token
            case .failure(let error):
                TaskData.notificationCenter.post(name: .tokenRefreshFailed,
                                                 object: token,
                                                 userInfo: ["error": error])
                newToken = nil
            }

            delegateCollection.invoke { $0.oauth(client: self, didRefresh: token, replacedWith: newToken) }
        }
    }
    
    /// Attempts to revoke the given token.
    ///
    /// A ``Token`` object may represent multiple token types, such as ``Token/accessToken`` or ``Token/refreshToken``. These individual token types can be targeted to be revoked.
    ///
    /// - Parameters:
    ///   - token: Token object.
    ///   - type: Type of token to revoke, default: ``Token/RevokeType/all``
    public func revoke(_ token: Token, type: Token.RevokeType = .all) async throws {
        let revokeTypes: [Token.RevokeType]
        if case .all = type {
            revokeTypes = Token.RevokeType.allCases.filter { type in
                guard let tokenType = type.tokenType else {
                    return false
                }

                return token.token(of: tokenType) != nil
            }

            guard !revokeTypes.isEmpty else {
                return
            }
        } else if let tokenType = type.tokenType {
            guard token.token(of: tokenType) != nil else {
                throw OAuth2Error.missingToken(type: tokenType)
            }

            revokeTypes = [type]
        } else {
            throw OAuth2Error.cannotRevoke(type: type)
        }
        
        let openIdConfiguration = try await self.openIdConfiguration()
        let clientConfiguration = self.configuration
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for revokeType in revokeTypes {
                group.addTask {
                    guard let tokenType = revokeType.tokenType,
                          let tokenString = token.token(of: tokenType)
                    else {
                        throw OAuth2Error.cannotRevoke(type: revokeType)
                    }
                    
                    let request = try Token.RevokeRequest(openIdConfiguration: openIdConfiguration,
                                                          clientConfiguration: clientConfiguration,
                                                          token: tokenString,
                                                          hint: tokenType,
                                                          configuration: [:])
                    _ = try await request.send(to: self)
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    /// Introspects the given token information.
    /// - Parameters:
    ///   - token: Token to introspect
    ///   - type: The type of value to introspect.
    public func introspect(token: Token, type: Token.Kind) async throws -> TokenInfo {
        let request = try Token.IntrospectRequest(openIdConfiguration: try await openIdConfiguration(),
                                                  clientConfiguration: configuration,
                                                  token: token,
                                                  type: type)
        return try await request.send(to: self).result
    }
    
    /// Fetches the ``UserInfo`` associated with the given token.
    /// - Parameters:
    ///   - token: Token to retrieve user information for.
    public func userInfo(token: Token) async throws -> UserInfo {
        let request = try UserInfo.Request(openIdConfiguration: try await openIdConfiguration(),
                                           token: token)
        return try await request.send(to: self).result
    }
    
    /// Retrieves the org's ``JWKS`` key configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Returns: The ``JWKS`` configuration for the org identified by the client's base URL.
    public func jwks() async throws -> JWKS {
        try await jwksAction.perform {
            try await KeysRequest(openIdConfiguration: try await openIdConfiguration(),
                                  clientId: configuration.clientId)
            .send(to: self)
            .result
        }
    }
    
    /// Attempts to exchange, and verify, a token from the supplied request.
    ///
    /// This also ensures the ``JWKS`` keyset is retrieved in parallel (if it hasn't already been cached), and verifies the ID and Access tokens to ensure validity.
    public func exchange<T: OAuth2TokenRequest>(token request: T) async throws -> APIResponse<Token> {
        async let jwks = jwks()
        let response = try await request.send(to: self)
        let token = response.result
        
        try await token.validate(using: self, with: request.tokenValidatorContext)
        if let idToken = token.idToken,
           try idToken.validate(using: try await jwks) == false
        {
            throw JWTError.signatureInvalid
        }

        return response
    }

    // MARK: Static Private properties / methods
    private static let lock = Lock()
    nonisolated(unsafe) private static var _defaultSession: (any URLSessionProtocol)?

    // MARK: Instance Private properties / methods
    private let lock = Lock()
    nonisolated(unsafe) private var _additionalHttpHeaders: [String: String]?

    nonisolated public let delegateCollection = DelegateCollection<any OAuth2ClientDelegate>()
    let refreshQueue: DispatchQueue

    let openIdConfigurationAction = CoalescedResult<OpenIdConfiguration>(taskName: "OpenIdConfiguration")
    let jwksAction = CoalescedResult<JWKS>(taskName: "JWKS")
}
// swiftlint:enable type_body_length

// Work around a bug in Swift 5.10 that ignores `nonisolated(unsafe)` on mutable stored properties.
#if swift(<6.0)
extension OAuth2Client: @unchecked Sendable {}
#else
extension OAuth2Client: Sendable {}
#endif

extension OAuth2Client {
    /// Asynchronously retrieves the org's OpenID configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Parameter completion: Completion block invoked with the result.
    public func openIdConfiguration(completion: @Sendable @escaping (Result<OpenIdConfiguration, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await openIdConfiguration()))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
    
    /// Asynchronously retrieves the org's ``JWKS`` key configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Parameter completion: Completion block invoked with the result.
    public func jwks(completion: @Sendable @escaping (Result<JWKS, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await jwks()))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
    
    /// Attempts to refresh the supplied token, using the ``Token/refreshToken`` if it is available.
    ///
    /// This method prevents multiple concurrent refresh requests to be performed for a given token, though all applicable completion blocks will be invoked once the token refresh has completed.
    /// - Parameters:
    ///   - token: Token to refresh.
    ///   - completion: Completion bock invoked with the result.
    public func refresh(_ token: Token, completion: @Sendable @escaping (Result<Token, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await refresh(token)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
    
    /// Attempts to revoke the given token.
    ///
    /// A ``Token`` object may represent multiple token types, such as ``Token/accessToken`` or ``Token/refreshToken``. These individual token types can be targeted to be revoked.
    ///
    /// - Parameters:
    ///   - token: Token object.
    ///   - type: Type of token to revoke.
    ///   - completion: Completion block to invoke once complete.
    public func revoke(_ token: Token, type: Token.RevokeType, completion: @Sendable @escaping (Result<Void, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await revoke(token, type: type)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }

    /// Introspects the given token information.
    /// - Parameters:
    ///   - token: Token to introspect
    ///   - type: The type of value to introspect.
    ///   - completion: Completion block to invoke once complete.
    public func introspect(token: Token, type: Token.Kind, completion: @Sendable @escaping (Result<TokenInfo, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await introspect(token: token, type: type)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }

    /// Fetches the ``UserInfo`` associated with the given token.
    /// - Parameters:
    ///   - token: Token to retrieve user information for.
    ///   - completion: Completion block invoked with the result.
    public func userInfo(token: Token, completion: @Sendable @escaping (Result<UserInfo, OAuth2Error>) -> Void) {
        Task {
            do {
                completion(.success(try await userInfo(token: token)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension OAuth2Client: APIClient {
    /// Exposes the base URL this authorization server is represented by.
    public var baseURL: URL { configuration.baseURL }
    
    /// Transforms HTTP response data into the appropriate error type, when requests are unsuccessful.
    /// - Parameter data: HTTP response body data for a failed URL request.
    /// - Returns: ``OktaAPIError`` or ``OAuth2ServerError``, depending on the type of error.
    public func error(from data: Data) -> (any Error)? {
        if let error = try? decode(OktaAPIError.self, from: data) {
            return error
        }
        
        if let error = try? decode(OAuth2ServerError.self, from: data) {
            return error
        }
        
        return nil
    }

    @_documentation(visibility: private)
    public func decode<T>(_ type: T.Type, from data: Data, parsing context: (any APIParsingContext)? = nil) throws -> T where T: Decodable {
        var info: [CodingUserInfoKey: any Sendable] = context?.codingUserInfo as? [CodingUserInfoKey: any Sendable] ?? [:]

        if let tokenRequest = context as? any OAuth2TokenRequest,
           info[.tokenContext] == nil
        {
            var clientSettings = info[.clientSettings] as? [String: String] ?? [:]
            if let tokenRequest = tokenRequest as? any AuthenticationFlowRequest,
               let persistValues = tokenRequest.context.persistValues
            {
                clientSettings.merge(persistValues) { (_, new) in new }
            }

            info[.tokenContext] = Token.Context(configuration: configuration,
                                                clientSettings: clientSettings)
        }
        
        if let jsonType = type as? any JSONDecodable.Type {
            guard let result = try jsonType.init(data, userInfo: info) as? T
            else {
                throw APIClientError.invalidResponse
            }
            return result
        } else {
            let jsonDecoder = defaultJSONDecoder()
            jsonDecoder.userInfo = info
            return try jsonDecoder.decode(type, from: data)
        }
    }
    
    @_documentation(visibility: private)
    public func willSend(request: inout URLRequest) {
        delegateCollection.invoke { $0.api(client: self, willSend: &request) }
    }
    
    @_documentation(visibility: private)
    public func didSend(request: URLRequest, received error: APIClientError, requestId: String?, rateLimit: APIRateLimit?) {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: error, requestId: requestId, rateLimit: rateLimit) }
    }

    @_documentation(visibility: private)
    public func shouldRetry(request: URLRequest) -> APIRetry {
        return delegateCollection.call({ $0.api(client: self, shouldRetry: request) }).first ?? .default
    }
    
    @_documentation(visibility: private)
    public func didSend(request: URLRequest, received response: HTTPURLResponse) {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: response) }
    }

    @_documentation(visibility: private)
    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) where T: Decodable {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: response) }
    }
}

extension Notification.Name {
    /// Notification broadcast when a new ``OAuth2Client`` instance is created.
    public static let oauth2ClientCreated = Notification.Name("com.okta.oauth2client.created")

    /// Notification broadcast when a ``Token`` is refreshed.
    public static let tokenRefreshed = Notification.Name("com.okta.token.refresh.success")

    /// Notification broadcast when a ``Token`` refresh fails.
    public static let tokenRefreshFailed = Notification.Name("com.okta.token.refresh.failed")
}
