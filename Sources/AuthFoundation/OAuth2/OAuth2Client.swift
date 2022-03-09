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
///
/// This class serves two purposes:
/// 1. Expose high-level actions a client can perform against an OAuth2 service.
/// 2. Connect authentication flows to the OAuth2 servers they intend to authenticate against.
///
/// Authentication flows represent the variety of ways authentication can occur, and in many cases involves multiple discrete steps. These often require interaction with individual actions (such as fetching OpenID configuration, accessing JWKS keys, and exchanging tokens), so these are encapsulated within the OAuth2Client for code sharing and ease of use.
///
/// The OAuth2Client is itself an APIClient, defined from within the AuthFoundation framework, and provides extensibility hooks.
public class OAuth2Client {
    /// The configuration for an ``OAuth2Client``.
    ///
    /// This defines the basic information necessary for interacting with an OAuth2 authorization server.
    public class Configuration: Codable, Equatable, Hashable, APIClientConfiguration {
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
    public var additionalHttpHeaders: [String:String]? = nil
    
    /// The OpenID configuration for this org.
    ///
    /// This value will be `nil` until the configuration has been retrieved through the ``openIdConfiguration(completion:)`` or ``openIdConfiguration()`` functions.
    @TimeSensitive
    private(set) public var openIdConfiguration: OpenIdConfiguration?

    /// The ``JWKS`` key set for this org.
    ///
    /// This value will be `nil` until the keys have been retrieved through the ``jwks(completion:)`` or ``jwks()`` functions.
    @TimeSensitive
    private(set) public var jwks: JWKS?

    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - domain: Okta domain to use for the base URL.
    ///   - session: Optional URLSession to use for network requests.
    convenience public init(domain: String, clientId: String, scopes: String, session: URLSessionProtocol? = nil) throws {
        self.init(try Configuration(domain: domain,
                                    clientId: clientId,
                                    scopes: scopes),
                  session: session)
    }
    
    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - domain: Okta domain to use for the base URL.
    ///   - session: Optional URLSession to use for network requests.
    convenience public init(baseURL: URL, clientId: String, scopes: String, session: URLSessionProtocol? = nil) {
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
                fetchOpenIdConfiguration { result in
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
    
    private lazy var refreshQueue: DispatchQueue = {
        DispatchQueue(label: "com.okta.refreshQueue.\(baseURL.host ?? "unknown")",
                      qos: .userInitiated,
                      attributes: .concurrent)
    }()
    private func performRefresh(token: Token, clientSettings: [String:String]) {
        guard let action = token.refreshAction else { return }
        
        delegateCollection.invoke { $0.oauth(client: self, willRefresh: token) }
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                self.refresh(Token.RefreshRequest(openIdConfiguration: configuration,
                                                  token: token,
                                                  configuration: clientSettings)) { result in
                    self.refreshQueue.sync(flags: .barrier) {
                        switch result {
                        case .success(let response):
                            action.finish(.success(response.result))
                            self.delegateCollection.invoke { $0.oauth(client: self, didRefresh: token, replacedWith: response.result) }
                            NotificationCenter.default.post(name: .tokenRefreshed, object: response.result)
                            
                        case .failure(let error):
                            action.finish(.failure(.network(error: error)))
                            self.delegateCollection.invoke { $0.oauth(client: self, didRefresh: token, replacedWith: nil) }
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
                self.revoke(request) { result in
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
    
    public func introspect(token: Token, type: Token.Kind, completion: @escaping (Result<[String:Claim], OAuth2Error>) -> Void) {
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                self.introspect(Token.IntrospectRequest(openIdConfiguration: configuration,
                                                        token: token,
                                                        type: type)) { result in
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
    
    public func userInfo(token: Token, completion: @escaping (Result<UserInfo, OAuth2Error>) -> Void) {
        openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                self.userInfo(UserInfo.Request(openIdConfiguration: configuration,
                                               token: token)) { result in
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
                        self.fetchKeys(KeysRequest(openIdConfiguration: configuration,
                                                   clientId: self.configuration.clientId)) { result in
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

    public func decode<T>(_ type: T.Type, from data: Data, userInfo: [CodingUserInfoKey:Any]? = nil) throws -> T where T: Decodable {
        var info: [CodingUserInfoKey:Any] = userInfo ?? [:]
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

    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) where T : Decodable {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: response) }
    }
}

extension OAuth2Client: UsesDelegateCollection {
    public typealias Delegate = OAuth2ClientDelegate

    /// Adds the supplied object as a delegate of this client.
    /// - Parameter delegate: Delegate to add.
    public func add(delegate: Delegate) { delegates += delegate }
    
    /// Removes the given delegate from this client.
    /// - Parameter delegate: Delegate to remove.
    public func remove(delegate: Delegate) { delegates -= delegate }
    
    public var delegateCollection: DelegateCollection<OAuth2ClientDelegate> {
        delegates
    }
}

extension Notification.Name {
    /// Notification broadcast when a new ``OAuth2Client`` instance is created.
    public static let oauth2ClientCreated = Notification.Name("com.okta.oauth2client.created")

    /// Notification broadcast when a ``Token`` is refreshed.
    public static let tokenRefreshed = Notification.Name("com.okta.token.refreshed")
}
