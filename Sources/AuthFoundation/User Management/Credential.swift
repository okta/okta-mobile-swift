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
    public static var allCredentials: [Credential] { coordinator.allCredentials }
    
    /// Returns a Credential instance for the given token.
    ///
    /// If a credential has previously been created for the given token, that cached instance will be returned.
    /// - Parameter token: Token to identify the user by.
    /// - Returns: Credential object that represents the given token.
    public static func `for`(token: Token) -> Credential { coordinator.for(token: token) }
    
    /// OAuth2 client for performing operations related to the user's token.
    public let oauth2: OAuth2Client

    /// The token this credential represents.
    @TimeSensitive<Token>
    public private(set) var token: Token

    /// The ``UserInfo`` describing this user.
    ///
    /// This value may be nil if the ``userInfo()`` or ``userInfo(completion:)`` methods haven't yet been called.
    @TimeSensitive<UserInfo?>
    public private(set) var userInfo: UserInfo?
    
    /// Initializer that creates a credential for the supplied token.
    /// - Parameter token: Token to create a credential for.
    public convenience init(token: Token) {
        let urlSession = type(of: self).credentialDataSource.urlSession(for: token)
        self.init(token: token, oauth2: OAuth2Client(token.context.configuration,
                                                     session: urlSession))
    }
    
    /// Initializer that creates a credential for a given token, using a custom OAuth2Client instance.
    /// - Parameters:
    ///   - token: Token
    ///   - client: Client instance.
    public convenience init(token: Token, oauth2 client: OAuth2Client) {
        self.init(token: token, oauth2: client, coordinator: Credential.coordinator)
    }
    
    init(token: Token, oauth2 client: OAuth2Client, coordinator: CredentialCoordinator) {
        self.token = token
        self.oauth2 = client
        self.coordinator = coordinator

        self.oauth2.add(delegate: self)
    }

    // MARK: Private properties
    fileprivate static let coordinator = CredentialCoordinatorImpl()
    internal weak var coordinator: CredentialCoordinator?
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
