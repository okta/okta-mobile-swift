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

    /// Notification broadcast when a credential fails to refresh.
    public static let credentialRefreshFailed = Notification.Name("com.okta.credential.refresh.failed")
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension Credential {
    /// Attempt to refresh the token.
    public func refresh(clientSecret: String, resource: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            refresh(clientSecret: clientSecret, resource: resource) { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Attempt to refresh the token.
    public func refresh() async throws {
        try await withCheckedThrowingContinuation { continuation in
            refresh(clientSecret: "", resource: "") { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Attempt to refresh the token if it either has expired, or is about to expire.
    public func refreshIfNeeded(graceInterval: TimeInterval = Credential.refreshGraceInterval) async throws {
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
    public func revoke(type: Token.RevokeType = .all) async throws {
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
            userInfo { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Introspect the token to check it for validity, and read the additional information associated with it.
    /// - Parameters:
    ///   - type: Type of token to introspect.
    public func introspect(_ type: Token.Kind) async throws -> TokenInfo {
        try await withCheckedThrowingContinuation { continuation in
            oauth2.introspect(token: token, type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
