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

extension Notification.Name {
    /// Notification broadcast when the ``Credential/default`` value changes.
    public static let defaultCredentialChanged = Notification.Name("com.okta.defaultCredentialChanged")
    
    /// Notification broadcast when a new ``Credential`` instance is created.
    ///
    /// > Note: This notification is only sent when the ``CredentialDataSource`` creates a credential. If you use the ``Credential/init(token:oauth2:)`` method directly, this notification is not sent.
    public static let credentialCreated = Notification.Name("com.okta.credential.created")

    /// Notification broadcast when a credential is removed from storage.
    public static let credentialRemoved = Notification.Name("com.okta.credential.removed")
}

/// Errors that may occur in the process of managing credentials.
public enum CredentialError: Error {
    /// Thrown when a credential no longer has a weak reference to the coordinator that was used to create it.
    case missingCoordinator
    
    /// Thrown when a Credential is initialized with a ``Token`` and ``OAuth2Client`` with mismatched client configuration.
    case incorrectClientConfiguration
}

/// Convenience object that wraps a ``Token``, providing methods and properties for interacting with credential resources.
///
/// This class can be used as a convenience mechanism for managing stored credentials, performing operations on or for a user using their credentials, and interacting with resources scoped to the credential.
public class Credential {
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
    
    /// Returns a Credential instance for the given token.
    ///
    /// If a credential has previously been created for the given token, that cached instance will be returned.
    /// - Parameter token: Token to identify the user by.
    /// - Returns: Credential object that represents the given token.
    public static func with(token: Token) throws -> Credential {
        try coordinator.with(token: token)
    }
    
    /// Returns the ``Credential`` that matches the given ID.
    /// - Parameter id: ID for the credential to return.
    /// - Returns: Credential matching the ID.
    public static func with(id: String) throws -> Credential? {
        try coordinator.with(id: id)
    }
    
    /// Returns a collection of ``Credential`` instances that match the given expression.
    /// - Parameter expression: Expression used to filter the list of tokens.
    /// - Returns: Collection of credentials.
    public static func find(where expression: @escaping (Token.Metadata) -> Bool) throws -> [Credential] {
        try coordinator.find(where: expression)
    }
    
    /// Stores the given token for later use.
    /// - Parameters:
    ///   - token: Token to store.
    ///   - tags: Optional developer-assigned tags to associate with this token.
    /// - Returns: Credential representing this token.
    @discardableResult
    public static func store(token: Token, tags: [String:String] = [:]) throws -> Credential {
        try coordinator.store(token: token, tags: tags)
    }
    
    /// OAuth2 client for performing operations related to the user's token.
    public let oauth2: OAuth2Client
    
    /// The ID the token is identified by within storage.
    public lazy var id: String = { token.id }()
    
    /// The metadata associated with this credential.
    ///
    /// This property can be used to associate application-specific information with a ``Token``. This can be used to identify which token should be associated with certain parts of your application.
    ///
    /// > Important: Errors thrown from the setter are silently ignored. If you would like to handle errors when changing metadata, see the ``setTags(_:)`` function.
    public var tags: [String:String] {
        get { _metadata.tags }
        set {
            try? setTags(newValue)
        }
    }
    
    /// Updates the metadata associated with this credential.
    ///
    /// This is used internally by the ``tags`` setter, except the use of this function allows you to catch errors.
    /// - Parameter metadata: Metadata to set.
    public func setTags(_ tags: [String:String]) throws {
        guard let coordinator = coordinator else {
            throw CredentialError.missingCoordinator
        }
     
        let metadata = Token.Metadata(token: token, tags: tags)
        try coordinator.tokenStorage.setMetadata(metadata)

        _metadata = metadata
    }
    
    /// The token this credential represents.
    @TimeSensitive<Token>
    public private(set) var token: Token

    /// The ``UserInfo`` describing this user.
    ///
    /// This value may be nil if the ``userInfo()`` or ``userInfo(completion:)`` methods haven't yet been called.
    @TimeSensitive<UserInfo?>
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
    }

    deinit {
        stopAutomaticRefresh()
    }
    
    // MARK: Private properties
    fileprivate static let coordinator = CredentialCoordinatorImpl()
    internal weak var coordinator: CredentialCoordinator?

    private lazy var _metadata: Token.Metadata = {
        if let metadata = try? coordinator?.tokenStorage.metadata(for: token.id) {
            return metadata
        }
        
        return Token.Metadata(id: id)
    }()
    
    private(set) internal var automaticRefreshTimer: DispatchSourceTimer?
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
}

extension Credential {
    /// Convenience method that decorates the given URLRequest with the appropriate authorization headers to make a request using the credential's current token.
    /// - Parameter request: Request to decorate with the appropriate authorization header.
    public func authorize(request: inout URLRequest) {
        request.setValue(token.authorizationHeader, forHTTPHeaderField: "Authorization")
    }
}

extension Credential {
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
}

extension Credential: OAuth2ClientDelegate {
    public func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        guard token == self.token,
              let newToken = newToken
        else {
            return
        }

        self.token = newToken
    }
}

extension Credential: Identifiable {
}

extension Credential: Equatable {
    public static func == (lhs: Credential, rhs: Credential) -> Bool {
        lhs.token == rhs.token
    }
}

extension Credential {
    /// Remove the credential, and its token, from storage.
    public func remove() throws {
        guard let coordinator = coordinator else {
            throw CredentialError.missingCoordinator
        }
     
        try coordinator.remove(credential: self)
    }
    
    /// Attempt to refresh the token.
    /// - Parameter completion: Completion block invoked when a result is returned.
    public func refresh(completion: ((Result<Token, OAuth2Error>) -> Void)? = nil) {
        oauth2.refresh(token) { result in
            defer { completion?(result) }
            
            if case let .success(token) = result {
                self.token = token
            }
        }
    }
    
    /// Attempt to refresh the token if it either has expired, or is about to expire.
    /// - Parameter completion: Completion block invoked with either the new token generated as a result of the refresh, or the current token if a refresh was unnecessary.
    public func refreshIfNeeded(graceInterval: TimeInterval = Credential.refreshGraceInterval,
                                completion: ((Result<Token, OAuth2Error>) -> Void)? = nil)
    {
        if let expiresAt = token.expiresAt,
            expiresAt.timeIntervalSinceNow <= graceInterval
        {
            refresh(completion: completion)
        } else {
            completion?(.success(token))
        }
    }
    
    /// Attempt to revoke one or more of the tokens.
    /// - Parameters:
    ///   - type: The token type to revoke.
    ///   - completion: Completion block called when the operation completes.
    public func revoke(type: Token.RevokeType = .accessToken, completion: ((Result<Void, OAuth2Error>) -> Void)? = nil) {
        oauth2.revoke(token, type: type) { result in
            // Remove the credential from storage if the access token was revoked
            if case .success(_) = result,
               type == .accessToken
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
    public func introspect(_ type: Token.Kind, completion: ((Result<TokenInfo, OAuth2Error>) -> Void)? = nil) {
        oauth2.introspect(token: token, type: type) { result in
            completion?(result)
        }
    }

    /// Fetches the user info for this credential.
    ///
    /// In addition to passing the result to the provided completion block, a successful request will result in the ``Credential/userInfo`` property being set with the new value for later use.
    /// - Parameter completion: Optional completion block to be invoked when a result is returned.
    public func userInfo(completion: ((Result<UserInfo, OAuth2Error>) -> Void)? = nil) {
        oauth2.userInfo(token: token) { result in
            defer { completion?(result) }
            
            if case let .success(userInfo) = result {
                self.userInfo = userInfo
            }
        }
    }
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension Credential {
    /// Attempt to refresh the token.
    /// - Returns: The new token generated as a result of the refresh.
    @discardableResult
    public func refresh() async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            refresh() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Attempt to refresh the token if it either has expired, or is about to expire.
    /// - Returns: The new token generated as a result of the refresh, or the current token if a refresh was unnecessary.
    public func refreshIfNeeded(graceInterval: TimeInterval = Credential.refreshGraceInterval) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            refreshIfNeeded(graceInterval: graceInterval) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Asynchronous convenience method that decorates the given URLRequest with the appropriate authorization headers to make a request using the credential's current token.
    ///
    /// This asynchronous variant ensures that the token has been refreshed, if needed, prior to adding the appropriate headers to the request.
    /// - Parameter request: Request to decorate with the appropriate authorization header.
    public func authorize(_ request: inout URLRequest) async {
        _ = try? await refreshIfNeeded()
        authorize(request: &request)
    }
    
    /// Attempt to revoke one or more of the tokens.
    /// - Parameters:
    ///   - type: The token type to revoke.
    public func revoke(type: Token.RevokeType = .accessToken) async throws {
        try await withCheckedThrowingContinuation { continuation in
            revoke(type: type) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Fetches the user info for this user.
    ///
    /// In addition to passing the result to the provided completion block, a successful request will result in the ``UserInfo`` property being set with the new value for later use.
    /// - Returns: The user info for this user.
    public func userInfo() async throws -> UserInfo {
        try await withCheckedThrowingContinuation { continuation in
            userInfo() { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
