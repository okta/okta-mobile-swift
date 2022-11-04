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

#if canImport(LocalAuthentication) && !os(tvOS)
import LocalAuthentication

extension LAContext: TokenAuthenticationContext {}
#endif

public protocol TokenAuthenticationContext {}

/// Protocol used to customize the way tokens are stored, updated, and removed throughout the lifecycle of an application.
///
/// A default implementation is provided, but for advanced use-cases, you may implement this protocol yourself and assign an instance to the ``Credential/tokenStorage`` property.
///
/// > Warning: When implementing a custom token storage class, it's vitally important that you do not directly invoke any of these methods yourself. These methods are intended to be called on-demand by the other AuthFoundation classes, and the behavior is undefined if these methods are called directly by the developer.
public protocol TokenStorage {
    /// Mandatory delegate property that is used to communicate changes to the token store to the rest of the user management system.
    var delegate: TokenStorageDelegate? { get set }
    
    /// Accessor for defining which token shall be the default.
    ///
    /// > Note: Setting a new token should implicitly invoke ``add(token:metadata:security:)`` if the token doesn't previously exist within storage.
    /// >
    /// > The ``TokenStorageDelegate/token(storage:defaultChanged:)`` method should also be invoked.
    var defaultTokenID: String? { get }

    func setDefaultTokenID(_ id: String?) throws

    /// Returns all tokens currently in storage.
    var allIDs: [String] { get }
    
    /// Adds the given token.
    ///
    /// This should throw ``TokenError/duplicateTokenAdded`` if the token already exists in storage.
    ///
    /// > Note: This method should invoke the ``TokenStorageDelegate/token(storage:added:token:)`` delegate method.
    func add(token: Token, metadata: Token.Metadata?, security: [Credential.Security]) throws
    
    /// Associates the given metadata with the token identified by the given ID.
    func setMetadata(_ metadata: Token.Metadata) throws
    
    /// Returns the metadata for the given token ID.
    /// - Returns: Metadata for this token ID.
    func metadata(for id: String) throws -> Token.Metadata
    
    /// Replaces an existing token with a new one.
    ///
    /// This can be used during the token refresh process, and indicates that one token is semantically the same as another. If the token being replaced is the default, the default value should be updated as well.
    ///
    /// > Note: This method should invoke the ``TokenStorageDelegate/token(storage:replaced:with:)`` and ``TokenStorageDelegate/token(storage:defaultChanged:)`` methods as needed.
    func replace(token id: String, with token: Token, security: [Credential.Security]?) throws

    /// Removes the given token.
    ///
    /// > Note: This method should invoke the  ``TokenStorageDelegate/token(storage:removed:)`` method.
    func remove(id: String) throws
    
    /// Returns a token for the given ID.
    /// - Returns: Token that matches the given ID.
    func get(token id: String, prompt: String?, authenticationContext: TokenAuthenticationContext?) throws -> Token
}

/// Protocol that custom ``TokenStorage`` instances are required to communicate changes to.
public protocol TokenStorageDelegate: AnyObject {
    /// Sent when the default token has been changed.
    func token(storage: TokenStorage, defaultChanged id: String?)
    
    /// Sent when a new token has been added.
    ///
    /// > Important: This message should only be sent when a token is actually new. If the token is semantically identical to another one already in storage, the ``token(storage:replaced:with:)`` message should be sent instead.
    func token(storage: TokenStorage, added id: String, token: Token)
    
    /// Sent when a token has been removed from storage.
    func token(storage: TokenStorage, removed id: String)
    
    /// Sent when a token has been updated within storage.
    ///
    /// There are circumstances when a token that already exists within storage needs to be replaced or updated. For example, when a token is refreshed, even though the new token differs, it represents the same resources and capabilities as the previous token.
    ///
    /// As a result, this message is used to convey that a token has been updated, but not removed or newly added.
    func token(storage: TokenStorage, replaced id: String, with newToken: Token)
}
