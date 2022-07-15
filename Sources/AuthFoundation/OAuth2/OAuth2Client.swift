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

#if os(Linux)
import FoundationNetworking
#endif

/// Delegate protocol used by ``OAuth2Client`` to communicate important events.
public protocol OAuth2ClientDelegate: APIClientDelegate {
    /// Sent before a token will begin to refresh.
    func oauth(client: OAuth2Client, willRefresh token: Token)

    /// Sent when a token has finished refreshing.
    func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?)
}

extension OAuth2ClientDelegate {
    public func oauth(client: OAuth2Client, willRefresh token: Token) {}
    public func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {}
}

/// An OAuth2 client, used to interact with a given authorization server.
public final class OAuth2Client {
    /// The configuration for an ``OAuth2Client``.
    ///
    /// This defines the basic information necessary for interacting with an OAuth2 authorization server.
    public final class Configuration: Codable, Equatable, Hashable, APIClientConfiguration {
        /// The base URL for interactions with this OAuth2 server.
        public let baseURL: URL
        
        /// The discovery URL used to retrieve the ``OpenIdConfiguration`` for this client.
        public let discoveryURL: URL
        
        /// The unique client ID representing this ``OAuth2Client``.
        public let clientId: String
        
        /// The list of OAuth2 scopes requested for this client.
        public let scopes: String
        
        /// Initializer for constructing an OAuth2Client.
        /// - Parameters:
        ///   - baseURL: Base URL.
        ///   - discoveryURL: Discovery URL, or `nil` to accept the default OpenIDConfiguration endpoint.
        ///   - clientId: The client ID.
        ///   - scopes: The list of OAuth2 scopes.
        public init(baseURL: URL, discoveryURL: URL? = nil, clientId: String, scopes: String) {
            var relativeURL = baseURL

            // Ensure the base URL contains a trailing slash in its path, so request paths can be safely appended.
            if !relativeURL.lastPathComponent.isEmpty {
                relativeURL.appendPathComponent("")
            }
            
            self.baseURL = baseURL
            self.discoveryURL = discoveryURL ?? relativeURL.appendingPathComponent(".well-known/openid-configuration")
            self.clientId = clientId
            self.scopes = scopes
        }
        
        /// Convenience initializer to create a client using a simple domain name.
        /// - Parameters:
        ///   - domain: Domain name for the OAuth2 client.
        ///   - clientId: The client ID.
        ///   - scopes: The list of OAuth2 scopes.
        public convenience init(domain: String, clientId: String, scopes: String) throws {
            guard let url = URL(string: "https://\(domain)") else {
                throw OAuth2Error.invalidUrl
            }

            self.init(baseURL: url, clientId: clientId, scopes: scopes)
        }

        public static func == (lhs: OAuth2Client.Configuration, rhs: OAuth2Client.Configuration) -> Bool {
            lhs.baseURL == rhs.baseURL &&
            lhs.clientId == rhs.clientId &&
            lhs.scopes == rhs.scopes
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(baseURL)
            hasher.combine(clientId)
            hasher.combine(scopes)
        }
    }
    
    /// The URLSession used by this client for network requests.
    public let session: URLSessionProtocol
    
    /// The configuration that identifies this OAuth2 client.
    public let configuration: Configuration
    
    /// Additional HTTP headers to include in outgoing network requests.
    public var additionalHttpHeaders: [String: String]? = nil
    
    /// The OpenID configuration for this org.
    ///
    /// This value will be `nil` until the configuration has been retrieved through the ``openIdConfiguration(completion:)`` or ``openIdConfiguration()`` functions.
    @TimeSensitive
    public private(set) var openIdConfiguration: OpenIdConfiguration?

    /// The ``JWKS`` key set for this org.
    ///
    /// This value will be `nil` until the keys have been retrieved through the ``jwks(completion:)`` or ``jwks()`` functions.
    @TimeSensitive
    public private(set) var jwks: JWKS?

    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - domain: Okta domain to use for the base URL.
    ///   - session: Optional URLSession to use for network requests.
    public convenience init(domain: String, clientId: String, scopes: String, session: URLSessionProtocol? = nil) throws {
        self.init(try Configuration(domain: domain,
                                    clientId: clientId,
                                    scopes: scopes),
                  session: session)
    }
    
    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - domain: Okta domain to use for the base URL.
    ///   - session: Optional URLSession to use for network requests.
    public convenience init(baseURL: URL, clientId: String, scopes: String, session: URLSessionProtocol? = nil) {
        self.init(Configuration(baseURL: baseURL,
                                clientId: clientId,
                                scopes: scopes),
                  session: session)
    }
    
    /// Constructs an OAuth2Client for the given base URL.
    /// - Parameters:
    ///   - baseURL: Base URL representing the Okta domain to use.
    ///   - session: Optional URLSession to use for network requests.
    public init(_ configuration: Configuration, session: URLSessionProtocol? = nil) {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.configuration = configuration
        self.session = session ?? URLSession.shared
        
        NotificationCenter.default.post(name: .oauth2ClientCreated, object: self)
    }
    
    /// Retrieves the org's OpenID configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Parameter completion: Completion block invoked with the result.
    public func openIdConfiguration(completion: @escaping (Result<OpenIdConfiguration, OAuth2Error>) -> Void) {
        if let openIdConfiguration = openIdConfiguration {
            completion(.success(openIdConfiguration))
        } else {
            configurationQueue.sync {
                guard openIdConfigurationAction == nil else {
                    openIdConfigurationAction?.add(completion)
                    return
                }
                
                let action: CoalescedResult<Result<OpenIdConfiguration, OAuth2Error>> = CoalescedResult()
                action.add(completion)
                
                openIdConfigurationAction = action
                
                let request = OpenIdConfigurationRequest(baseURL: baseURL)
                request.send(to: self) { result in
                    self.configurationQueue.sync(flags: .barrier) {
                        self.openIdConfigurationAction = nil
                        
                        switch result {
                        case .success(let response):
                            self.openIdConfiguration = response.result
                            
                            self.configurationQueue.async {
                                action.finish(.success(response.result))
                            }
                        case .failure(let error):
                            self.configurationQueue.async {
                                action.finish(.failure(.network(error: error)))
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Attempts to refresh the supplied token, using the ``Token/refreshToken`` if it is available.
    ///
    /// This method prevents multiple concurrent refresh requests to be performed for a given token, though all applicable completion blocks will be invoked once the token refresh has completed.
    /// - Parameters:
    ///   - token: Token to refresh.
    ///   - completion: Completion bock invoked with the result.
    public func refresh(_ token: Token, completion: @escaping (Result<Token, OAuth2Error>) -> Void) {
        guard let clientSettings = token.context.clientSettings else {
            completion(.failure(.missingToken(type: .refreshToken)))
            return
        }
        
        refreshQueue.sync {
            guard token.refreshAction == nil else {
                token.refreshAction?.add(completion)
                return
            }
            
            token.refreshAction = CoalescedResult()
            token.refreshAction?.add(completion)
            performRefresh(token: token, clientSettings: clientSettings)
        }
    }
    
    private(set) lazy var refreshQueue: DispatchQueue = {
        DispatchQueue(label: "com.okta.refreshQueue.\(baseURL.host ?? "unknown")",
                      qos: .userInitiated,
                      attributes: .concurrent)
    }()
    private func performRefresh(token: Token, clientSettings: [String: String]) {
        guard let action = token.refreshAction else { return }
        
        delegateCollection.invoke { $0.oauth(client: self, willRefresh: token) }
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = Token.RefreshRequest(openIdConfiguration: configuration,
                                                   token: token,
                                                   configuration: clientSettings)
                request.send(to: self) { result in
                    self.refreshQueue.sync(flags: .barrier) {
                        switch result {
                        case .success(let response):
                            let newToken = response.result.token(merging: token)
                            
                            action.finish(.success(newToken))
                            
                            self.delegateCollection.invoke { $0.oauth(client: self, didRefresh: token, replacedWith: newToken) }
                            NotificationCenter.default.post(name: .tokenRefreshed, object: newToken)
                            
                        case .failure(let error):
                            action.finish(.failure(.network(error: error)))
                            self.delegateCollection.invoke { $0.oauth(client: self, didRefresh: token, replacedWith: nil) }
                            
                            NotificationCenter.default.post(name: .tokenRefreshFailed,
                                                            object: token,
                                                            userInfo: ["error": error])
                        }
                        
                        token.refreshAction = nil
                    }
                }
            case .failure(let error):
                action.finish(.failure(error))
                self.delegateCollection.invoke { $0.oauth(client: self, didRefresh: token, replacedWith: nil) }
                token.refreshAction = nil
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
    public func revoke(_ token: Token, type: Token.RevokeType, completion: @escaping (Result<Void, OAuth2Error>) -> Void) {
        let tokenType = type.tokenType
        guard let tokenString = token.token(of: tokenType) else {
            completion(.failure(.missingToken(type: tokenType)))
            return
        }
        
        guard let clientSettings = token.context.clientSettings else {
            completion(.failure(.missingClientConfiguration))
            return
        }
        
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = Token.RevokeRequest(openIdConfiguration: configuration,
                                                  token: tokenString,
                                                  hint: tokenType,
                                                  configuration: clientSettings)
                request.send(to: self) { result in
                    switch result {
                    case .success(_):
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(.network(error: error)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Introspects the given token information.
    /// - Parameters:
    ///   - token: Token to introspect
    ///   - type: The type of value to introspect.
    ///   - completion: Completion block to invoke once complete.
    public func introspect(token: Token, type: Token.Kind, completion: @escaping (Result<TokenInfo, OAuth2Error>) -> Void) {
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = Token.IntrospectRequest(openIdConfiguration: configuration,
                                                      token: token,
                                                      type: type)
                request.send(to: self) { result in
                    switch result {
                    case .success(let response):
                        completion(.success(response.result))
                    case .failure(let error):
                        completion(.failure(.network(error: error)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Fetches the ``UserInfo`` associated with the given token.
    /// - Parameters:
    ///   - token: Token to retrieve user information for.
    ///   - completion: Completion block invoked with the result.
    public func userInfo(token: Token, completion: @escaping (Result<UserInfo, OAuth2Error>) -> Void) {
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = UserInfo.Request(openIdConfiguration: configuration,
                                               token: token)
                request.send(to: self) { result in
                    switch result {
                    case .success(let response):
                        completion(.success(response.result))
                    case .failure(let error):
                        completion(.failure(.network(error: error)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Retrieves the org's ``JWKS`` key configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Parameter completion: Completion block invoked with the result.
    public func jwks(completion: @escaping (Result<JWKS, OAuth2Error>) -> Void) {
        if let jwks = jwks {
            completion(.success(jwks))
        } else {
            jwksQueue.sync {
                guard jwksAction == nil else {
                    jwksAction?.add(completion)
                    return
                }
                
                let action: CoalescedResult<Result<JWKS, OAuth2Error>> = CoalescedResult()
                action.add(completion)
                
                jwksAction = action
                openIdConfiguration { result in
                    switch result {
                    case .success(let configuration):
                        let request = KeysRequest(openIdConfiguration: configuration,
                                                  clientId: self.configuration.clientId)
                        request.send(to: self) { result in
                            self.jwksQueue.sync(flags: .barrier) {
                                self.jwksAction = nil

                                switch result {
                                case .success(let response):
                                    self.jwks = response.result
                                    self.jwksQueue.async {
                                        action.finish(.success(response.result))
                                    }
                                case .failure(let error):
                                    self.jwksQueue.async {
                                        action.finish(.failure(.network(error: error)))
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        self.jwksAction = nil
                        self.jwksQueue.async {
                            action.finish(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    /// Attempts to exchange, and verify, a token from the supplied request.
    ///
    /// This also ensures the ``JWKS`` keyset is retrieved in parallel (if it hasn't already been cached), and verifies the ID and Access tokens to ensure validity.
    public func exchange<T: OAuth2TokenRequest>(token request: T, completion: @escaping (Result<APIResponse<Token>, APIClientError>) -> Void) {
        // Fetch the JWKS keys in parallel if necessary
        let group = DispatchGroup()
        var keySet = jwks
        if keySet == nil {
            group.enter()
            jwks { result in
                defer { group.leave() }
                if case let .success(response) = result {
                    keySet = response
                }
            }
        }
        
        // Exchange the token
        request.send(to: self) { result in
            // Wait for the JWKS keys, if necessary
            group.notify(queue: DispatchQueue.global()) { [weak self] in
                // Perform idToken/accessToken validation
                self?.validateToken(request: request,
                                    keySet: keySet,
                                    oauthTokenResponse: result,
                                    completion: completion)
            }
        }
    }
    
    private func validateToken<T: OAuth2TokenRequest>(request: T,
                                                      keySet: JWKS?,
                                                      oauthTokenResponse: Result<APIResponse<Token>, APIClientError>,
                                                      completion: @escaping (Result<APIResponse<Token>, APIClientError>) -> Void)
    {
        guard case let .success(response) = oauthTokenResponse else {
            completion(oauthTokenResponse)
            return
        }
        
        // Retrieves the org's OpenID configuration
        self.openIdConfiguration { result in
            switch result {
            case .failure(let error):
                completion(.failure(.serverError(error)))
            case .success:
                do {
                    try response.result.validate(using: self, with: request as? IDTokenValidatorContext)
                } catch {
                    completion(.failure(.validation(error: error)))
                    return
                }
                
                guard let idToken = response.result.idToken else {
                    completion(oauthTokenResponse)
                    return
                }
                
                guard let keySet = keySet else {
                    completion(.failure(.validation(error: JWTError.invalidKey)))
                    return
                }
                
                do {
                    if try idToken.validate(using: keySet) == false {
                        completion(.failure(.validation(error: JWTError.signatureInvalid)))
                        return
                    }
                } catch {
                    completion(.failure(.validation(error: error)))
                    return
                }
                completion(oauthTokenResponse)
            }
        }
    }

    // MARK: Private properties / methods
    private let delegates = DelegateCollection<OAuth2ClientDelegate>()

    private lazy var configurationQueue: DispatchQueue = {
        DispatchQueue(label: "com.okta.configurationQueue.\(baseURL.host ?? "unknown")",
                      qos: .userInitiated,
                      attributes: .concurrent)
    }()
    internal var openIdConfigurationAction: CoalescedResult<Result<OpenIdConfiguration, OAuth2Error>>?

    private lazy var jwksQueue: DispatchQueue = {
        DispatchQueue(label: "com.okta.jwksQueue.\(baseURL.host ?? "unknown")",
                      qos: .userInitiated,
                      attributes: .concurrent)
    }()
    internal var jwksAction: CoalescedResult<Result<JWKS, OAuth2Error>>?
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension OAuth2Client {
    /// Asynchronously retrieves the org's OpenID configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Returns: The OpenID configuration for the org identified by the client's base URL.
    public func openIdConfiguration() async throws -> OpenIdConfiguration {
        try await withCheckedThrowingContinuation { continuation in
            openIdConfiguration() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Asynchronously retrieves the org's ``JWKS`` key configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Returns: The ``JWKS`` configuration for the org identified by the client's base URL.
    public func jwks() async throws -> JWKS {
        try await withCheckedThrowingContinuation { continuation in
            jwks() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Attempts to refresh the supplied token, using the ``Token/refreshToken`` if it is available.
    ///
    /// This method prevents multiple concurrent refresh requests to be performed for a given token, though all applicable results will be returned once the token refresh has completed.
    /// - Parameters:
    ///   - token: Token to refresh.
    public func refresh(_ token: Token) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            refresh(token) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Attempts to revoke the given token.
    ///
    /// A ``Token`` object may represent multiple token types, such as ``Token/accessToken`` or ``Token/refreshToken``. These individual token types can be targeted to be revoked.
    ///
    /// - Parameters:
    ///   - token: Token object.
    ///   - type: Type of token to revoke, default: ``Token/RevokeType/accessToken``
    public func revoke(_ token: Token, type: Token.RevokeType = .accessToken) async throws {
        try await withCheckedThrowingContinuation { continuation in
            revoke(token, type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension OAuth2Client: APIClient {
    /// Exposes the base URL this authorization server is represented by.
    public var baseURL: URL { configuration.baseURL }
    
    /// Transforms HTTP response data into the appropriate error type, when requests are unsuccessful.
    /// - Parameter data: HTTP response body data for a failed URL request.
    /// - Returns: ``OktaAPIError`` or ``OAuth2ServerError``, depending on the type of error.
    public func error(from data: Data) -> Error? {
        if let error = try? decode(OktaAPIError.self, from: data) {
            return error
        }
        
        if let error = try? decode(OAuth2ServerError.self, from: data) {
            return error
        }
        
        return nil
    }

    public func decode<T>(_ type: T.Type, from data: Data, userInfo: [CodingUserInfoKey: Any]? = nil) throws -> T where T: Decodable {
        var info: [CodingUserInfoKey: Any] = userInfo ?? [:]
        if info[.apiClientConfiguration] == nil {
            info[.apiClientConfiguration] = configuration
        }
        
        let jsonDecoder: JSONDecoder
        if let jsonType = type as? JSONDecodable.Type {
            jsonDecoder = jsonType.jsonDecoder
        } else {
            jsonDecoder = defaultJSONDecoder
        }
        
        jsonDecoder.userInfo = info
        
        return try jsonDecoder.decode(type, from: data)
    }
    
    public func willSend(request: inout URLRequest) {
        delegateCollection.invoke { $0.api(client: self, willSend: &request) }
    }
    
    public func didSend(request: URLRequest, received error: APIClientError) {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: error) }
    }

    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) where T: Decodable {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: response) }
    }
}

extension OAuth2Client: UsesDelegateCollection {
    public typealias Delegate = OAuth2ClientDelegate

    public var delegateCollection: DelegateCollection<OAuth2ClientDelegate> {
        delegates
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
