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
    /// Notification broadcast when the ``User/default`` value changes.
    public static let defaultUserChanged = Notification.Name("com.okta.defaultUserChanged")
    
    /// Notification broadcast when a new ``User`` instance is created.
    ///
    /// > Note: This notification is only sent when the ``UserDataSource`` creates a user. If you use the ``User/init(token:oauth2:)`` method directly, this notification is not sent.
    public static let userCreated = Notification.Name("com.okta.user.created")

    /// Notification broadcast when a user is removed from storage.
    public static let userRemoved = Notification.Name("com.okta.user.removed")
}

public enum UserError: Error {
    case missingUserCoordinator
}

/// Convenience object that wraps a ``Token``, providing methods and properties for interacting with user resources.
///
/// This class can be used as a convenience mechanism for managing stored user credentials, performing operations on or for a user, and interacting with resources scoped to a user.
public class User {
    private static let coordinator = UserCoordinator()
    internal weak var coordinator: UserCoordinator?

    /// Data source used for creating and managing the creation and caching of ``User`` instances.
    public static var userDataSource: UserDataSource {
        get { coordinator.userDataSource }
        set { coordinator.userDataSource = newValue }
    }
    
    /// Storage instance used to abstract the secure offline storage and retrieval of user ``Token`` instances.
    public static var tokenStorage: TokenStorage {
        get { coordinator.tokenStorage }
        set { coordinator.tokenStorage = newValue }
    }
    
    /// The current or "default" user.
    ///
    /// This can be used as a convenience to store a user's token within storage, and to access the user in a safe way. If the user's token isn't stored, this will automatically store the token for later use.
    public static var `default`: User? {
        get { coordinator.default }
        set { coordinator.default = newValue }
    }
    
    /// Lists all users currently stored within the user's application.
    public static var allUsers: [User] { coordinator.allUsers }
    
    /// Returns a User instance for the given token.
    ///
    /// If a user object has previously been created for the given token, that cached user instance will be returned.
    /// - Parameter token: Token to identify the user by.
    /// - Returns: User object that represents the given token.
    public static func `for`(token: Token) -> User { coordinator.for(token: token) }
    
    /// OAuth2 client for performing operations related to the user's token.
    public let oauth2: OAuth2Client

    /// The token this user instance represents.
    @TimeSensitive<Token>
    public private(set) var token: Token

    /// The ``UserInfo`` describing this user.
    ///
    /// This value may be nil if the ``userInfo()`` or ``userInfo(completion:)`` methods haven't yet been called.
    @TimeSensitive<UserInfo?>
    public private(set) var userInfo: UserInfo?
    
    public convenience init(token: Token) {
        let urlSession = type(of: self).userDataSource.urlSession(for: token)
        self.init(token: token, oauth2: OAuth2Client(baseURL: token.context.baseURL,
                                                     session: urlSession))
    }
    
    public init(token: Token, oauth2 client: OAuth2Client) {
        self.token = token
        self.oauth2 = client
    }
}

extension User: Identifiable {
}

extension User: Equatable {
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.token == rhs.token
    }
}

extension User {
    /// Remove the user, and its token, from storage.
    public func remove() throws {
        guard let coordinator = coordinator else {
            throw UserError.missingUserCoordinator
        }
        
        coordinator.userDataSource.remove(user: self)
        try coordinator.tokenStorage.remove(token: token)
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
            defer { completion?(result) }
            
            if case let .success(_) = result {
                // Do something with the result
            }
        }
    }
    
    /// Fetches the user info for this user.
    ///
    /// In addition to passing the result to the provided completion block, a successful request will result in the ``User/userInfo`` property being set with the new value for later use.
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

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension User {
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
    /// In addition to passing the result to the provided completion block, a successful request will result in the ``User/userInfo`` property being set with the new value for later use.
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
