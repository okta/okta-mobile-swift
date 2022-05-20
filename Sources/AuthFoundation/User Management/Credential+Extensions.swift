//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

    /// Notification broadcast when a credential has been migrated from a previous version.
    public static let credentialMigrated = Notification.Name("com.okta.credential.migrated")
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
