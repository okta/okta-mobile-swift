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

/// Convenience object that provides methods and properties for using a user's authentication tokens.
///
/// Once a user is authenticated within an application, the tokens' lifecycle must be managed to ensure it is properly refreshed as needed, is stored in a secure manner, and can be used to perform requests on behalf of the user. This class provides capabilities to accomplish all these tasks, while ensuring a convenient developer experience.
public final class Credential: Equatable, OAuth2ClientDelegate {
    /// The current or "default" credential.
    ///
    /// This can be used as a convenience to store a user's token within storage, and to access the user in a safe way. If the user's token isn't stored, this will automatically store the token for later use.
    public static var `default`: Credential? {
        get { coordinator.default }
        set { coordinator.default = newValue }
    }
    
    /// Lists all users currently stored within the user's application.
    public static var allIDs: [String] { coordinator.allIDs }
    
    /// The default grace interval used when refreshing tokens using ``Credential/refreshIfNeeded(graceInterval:completion:)`` or ``Credential/refreshIfNeeded(graceInterval:)``.
    ///
    /// This value may still be overridden by supplying an explicit `graceInterval` argument to the above methods.
    public static var refreshGraceInterval: TimeInterval = 300
    
    /// Returns the ``Credential`` that matches the given ID.
    /// - Parameters:
    ///   - id: ID for the credential to return.
    ///   - prompt: Optional prompt to show to the user when requesting biometric/Face ID user prompts.
    ///   - authenticationContext: Optional `LAContext` to use when retrieving credentials, on systems that support it.
    /// - Returns: Credential matching the ID.
    public static func with(id: String, prompt: String? = nil, authenticationContext: TokenAuthenticationContext? = nil) throws -> Credential? {
        try coordinator.with(id: id, prompt: prompt, authenticationContext: authenticationContext)
    }
    
    /// Returns a collection of ``Credential`` instances that match the given expression.
    ///
    /// The supplied expression can be used to filter out credentials based on information about the tokens (see ``Token/Metadata`` for more information).  For example:
    ///
    /// ```swift
    /// let credentials = try Credential.find(where: { info in
    ///      info.tags["customTag"] == "value" &&
    ///      info[.email] == "user@example.com"
    /// })
    /// ```
    ///
    /// The metadata object supplied to the expression contains information about custom tags, as well as claims included in the token's ID Token value.
    ///
    /// - Parameters:
    ///   - expression: Expression used to filter the list of tokens.
    ///   - prompt: Optional prompt to show to the user when requesting biometric/Face ID user prompts.
    ///   - authenticationContext: Optional `LAContext` to use when retrieving credentials, on systems that support it.
    /// - Returns: Collection of credentials that matches the given expression.
    public static func find(where expression: @escaping (Token.Metadata) -> Bool, prompt: String? = nil, authenticationContext: TokenAuthenticationContext? = nil) throws -> [Credential] {
        try coordinator.find(where: expression, prompt: prompt, authenticationContext: authenticationContext)
    }
    
    /// Stores the given token for later use.
    ///
    /// Once the token is stored, a ``Credential`` object is returned that provides conveniences to interact with the token. See <doc:ManagingUserCredentials> for more information.
    ///
    /// The optional arguments `tags` and `security` allow you to customize how this token is stored to assist with later retrieval of these objects.
    ///
    /// > Note: The ``Credential/Security/standard`` static property defines the standard set of security options to use when the `security` argument is not provided. To change the default values used when storing credentials, you can change that property to fit your application's needs.
    ///
    /// - Parameters:
    ///   - token: Token to store.
    ///   - tags: Optional developer-assigned tags that can enable you provide additional context to help with differentiating between multiple credentials, or to indicate the intended use for a particular token.
    ///   - options: Optional collection of security options used to customize how the token is stored.
    /// - Returns: Credential representing this token.
    @discardableResult
    public static func store(_ token: Token,
                             tags: [String: String] = [:],
                             security options: [Security] = Security.standard
    ) throws -> Credential {
        try coordinator.store(token: token, tags: tags, security: options)
    }

    /// Data source used for creating and managing the creation and caching of ``Credential`` instances.
    public static var credentialDataSource: CredentialDataSource {
        get { coordinator.credentialDataSource }
        set { coordinator.credentialDataSource = newValue }
    }
    
    /// Storage instance used to abstract the secure offline storage and retrieval of ``Token`` instances.
    public static var tokenStorage: TokenStorage {
        get { coordinator.tokenStorage }
        set { coordinator.tokenStorage = newValue }
    }

    public static func == (lhs: Credential, rhs: Credential) -> Bool {
        lhs.token == rhs.token
    }

    /// OAuth2 client for performing operations related to the user's token.
    public let oauth2: OAuth2Client
    
    /// The ID the token is identified by within storage.
    ///
    /// This value is automatically generated when the token is stored, and is a way to uniquely identify a token within storage. This value corresponds to the IDs found in the ``allIDs`` static property.
    public lazy var id: String = { token.id }()
    
    /// The metadata associated with this credential.
    ///
    /// This property can be used to associate application-specific information with a ``Token``. This can be used to identify which token should be associated with certain parts of your application.
    ///
    /// > Important: Errors thrown from the setter are silently ignored. If you would like to handle errors when changing metadata, see the ``setTags(_:)`` function.
    public var tags: [String: String] {
        get { _metadata.tags }
        set {
            try? setTags(newValue)
        }
    }
    
    /// Updates the metadata associated with this credential.
    ///
    /// This is used internally by the ``tags`` setter, except the use of this function allows you to catch errors.
    /// - Parameter metadata: Metadata to set.
    public func setTags(_ tags: [String: String]) throws {
        guard let coordinator = coordinator else {
            throw CredentialError.missingCoordinator
        }
     
        let metadata = Token.Metadata(token: token, tags: tags)
        try coordinator.tokenStorage.setMetadata(metadata)

        _metadata = metadata
    }
    
    /// The token this credential represents.
    public private(set) var token: Token {
        didSet {
            observeToken(token)
        }
    }

    /// The ``UserInfo`` describing this user.
    ///
    /// This value may be nil if the ``userInfo()`` or ``userInfo(completion:)`` methods haven't yet been called.
    public private(set) var userInfo: UserInfo?
    
    /// Indicates this credential's token should automatically be refreshed prior to its expiration.
    ///
    /// This property can be used to ensure a token is available for use, by refreshing the token automatically prior to its expiration. This uses the ``Credential/refreshGraceInterval`` in conjunction with the current ``TimeCoordinator`` instance, to refresh the token before its scheduled expiration.
    public var automaticRefresh: Bool = false {
        didSet {
            guard oldValue != automaticRefresh else { return }
            if automaticRefresh {
                startAutomaticRefresh()
            } else {
                stopAutomaticRefresh()
            }
        }
    }
    
    /// Convenience method that decorates the given URLRequest with the appropriate authorization headers to make a request using the credential's current token.
    /// - Parameter request: Request to decorate with the appropriate authorization header.
    public func authorize(request: inout URLRequest) {
        request.setValue(token.authorizationHeader, forHTTPHeaderField: "Authorization")
    }

    /// Remove the credential, and its token, from storage.
    public func remove() throws {
        guard let coordinator = coordinator else {
            throw CredentialError.missingCoordinator
        }
     
        try coordinator.remove(credential: self)
    }
    
    /// Attempt to refresh the token.
    /// - Parameter completion: Completion block invoked when a result is returned.
    public func refresh(clientSecret: String, resource: String, completion: @escaping ((Result<Void, OAuth2Error>) -> Void)) {
        oauth2.refresh(token, clientSecret: clientSecret, resource: resource) { result in
            switch result {
            case .success(let token):
                self.token = token
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Attempt to refresh the token if it either has expired, or is about to expire.
    /// - Parameter completion: Completion block invoked to indicate the status of the token, if the refresh was successful or if an error occurred.
    public func refreshIfNeeded(graceInterval: TimeInterval = Credential.refreshGraceInterval,
                                completion: @escaping (Result<Void, OAuth2Error>) -> Void)
    {
        if let expiresAt = token.expiresAt,
            expiresAt.timeIntervalSinceNow <= graceInterval
        {
            refresh(clientSecret: "", resource: "", completion: completion)
        } else {
            completion(.success(()))
        }
    }
    
    /// Attempt to revoke one or more of the tokens.
    ///
    /// Revoking a token causes it to become invalidated on the server. The `type` argument can be used to specify which token to revoke.
    /// * ``Token/RevokeType/accessToken`` – Revokes the access token. If the `offline_access` scope was specified when authenticating, the refresh token may be used to recreate a new access token.
    /// * ``Token/RevokeType/refreshToken`` – If a refresh token is present (e.g. the `offline_access` scope was specified when authenticating), both the access token _and_ refresh token will become invalidated.
    /// * ``Token/RevokeType/deviceSecret`` – If the `device_sso` scope was specified when authenticating, this will invalidate the device secret, which will prevent other clients from creating new tokens using Device SSO.
    /// * ``Token/RevokeType/all`` - Revokes all applicable tokens associated with this object.
    ///
    /// If a credential is no longer valid, it will automatically be removed from storage. This is to prevent an application from thinking a valid user is signed in while having credentials that are incapable of being used.
    ///
    /// This may occur if the credential:
    /// 1. Has both an access token and a refresh token, and the ``Token/RevokeType/refreshToken`` type is supplied, or
    /// 1. Does not have a refresh token and the ``Token/RevokeType/accessToken`` type is supplied.
    /// - Parameters:
    ///   - type: The token type to revoke, defaulting to `.all`.
    ///   - completion: Completion block called when the operation completes.
    public func revoke(type: Token.RevokeType = .all, completion: ((Result<Void, OAuth2Error>) -> Void)?) {
        let shouldRemove = shouldRemove(for: type)
        
        oauth2.revoke(token, type: type) { result in
            // Remove the credential from storage if the access token was revoked
            if case .success = result,
               shouldRemove
            {
                do {
                    try self.coordinator?.remove(credential: self)
                } catch let error as OAuth2Error {
                    completion?(.failure(error))
                    return
                } catch {
                    completion?(.failure(OAuth2Error.error(error)))
                    return
                }
            }
            
            completion?(result)
        }
    }
    
    /// Introspect the token to check it for validity, and read the additional information associated with it.
    /// - Parameter completion: Completion block invoked when a result is returned.
    public func introspect(_ type: Token.Kind, completion: @escaping (Result<TokenInfo, OAuth2Error>) -> Void) {
        oauth2.introspect(token: token, type: type) { result in
            completion(result)
        }
    }

    /// Fetches the user info for this credential.
    ///
    /// In addition to passing the result to the provided completion block, a successful request will result in the ``Credential/userInfo`` property being set with the new value for later use.
    /// - Parameter completion: Optional completion block to be invoked when a result is returned.
    public func userInfo(completion: @escaping (Result<UserInfo, OAuth2Error>) -> Void) {
        oauth2.userInfo(token: token) { result in
            defer { completion(result) }
            
            if case let .success(userInfo) = result {
                self.userInfo = userInfo
            }
        }
    }

    /// Initializer that creates a credential for the supplied token.
    /// - Parameter token: Token to create a credential for.
    public convenience init(token: Token) {
        let urlSession = type(of: self).credentialDataSource.urlSession(for: token)
        self.init(token: token,
                  oauth2: OAuth2Client(token.context.configuration,
                                       session: urlSession),
                  coordinator: Credential.coordinator)
    }
    
    /// Initializer that creates a credential for a given token, using a custom OAuth2Client instance.
    /// - Parameters:
    ///   - token: Token
    ///   - client: Client instance.
    public convenience init(token: Token, oauth2 client: OAuth2Client) throws {
        guard token.context.configuration.clientId == client.configuration.clientId,
              token.context.configuration.baseURL == client.configuration.baseURL
        else {
            throw CredentialError.incorrectClientConfiguration
        }
        
        self.init(token: token,
                  oauth2: client,
                  coordinator: Credential.coordinator)
    }
    
    init(token: Token, oauth2 client: OAuth2Client, coordinator: CredentialCoordinator) {
        self.token = token
        self.oauth2 = client
        self.coordinator = coordinator

        self.oauth2.add(delegate: self)
        observeToken(token)
    }

    deinit {
        stopAutomaticRefresh()

        if let tokenObserver = tokenObserver {
            NotificationCenter.default.removeObserver(tokenObserver)
        }
    }
    
    // MARK: OAuth2ClientDelegate
    public func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        guard token.id == self.token.id,
              let newToken = newToken
        else {
            return
        }

        self.token = newToken
    }
    
    // MARK: Private properties
    static let coordinator = CredentialCoordinatorImpl()
    weak var coordinator: CredentialCoordinator?

    private lazy var _metadata: Token.Metadata = {
        if let metadata = try? coordinator?.tokenStorage.metadata(for: token.id) {
            return metadata
        }
        
        return Token.Metadata(id: id)
    }()
    
    internal private(set) var automaticRefreshTimer: DispatchSourceTimer?
    private func startAutomaticRefresh() {
        guard let timerSource = createAutomaticRefreshTimer() else { return }

        automaticRefreshTimer?.cancel()
        automaticRefreshTimer = timerSource
        timerSource.resume()
    }
    
    func stopAutomaticRefresh() {
        automaticRefreshTimer?.cancel()
        automaticRefreshTimer = nil
    }

    private var tokenObserver: NSObjectProtocol?
    private func observeToken(_ token: Token) {
        if let tokenObserver = tokenObserver {
            NotificationCenter.default.removeObserver(tokenObserver)
        }

        tokenObserver = NotificationCenter.default.addObserver(forName: .tokenRefreshFailed,
                                                               object: token,
                                                               queue: nil) { [weak self] notification in
            guard let self = self,
                  token == self.token
            else {
                return
            }
            
            NotificationCenter.default.post(name: .credentialRefreshFailed,
                                            object: self,
                                            userInfo: notification.userInfo)
        }
    }
}
