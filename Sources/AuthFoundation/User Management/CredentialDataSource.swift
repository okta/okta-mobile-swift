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

/// Protocol that enables a developer to interact with, and override, the default behavior for the lifecycle of ``Credential`` instances.
///
/// A default implementation is provided, but for advanced use-cases, you may implement this protocol yourself and assign an instance to the ``Credential/credentialDataSource`` property.
public protocol CredentialDataSource {
    /// Mandatory delegate property that is used to communicate when credentials within this data source are created or changed.
    var delegate: CredentialDataSourceDelegate? { get set }

    /// Enables developers to provide a custom URLSession when a credential is created for the given token.
    /// - Returns: URLSession to be used for this token, or `nil` to accept the default behavior.
    func urlSession(for token: Token) -> URLSessionProtocol
    
    /// Returns the number of credential objects currently cached within this datasource.
    ///
    /// > Note: This should not return the total number of available tokens, but rather the number of credential objects loaded within this cache.
    var credentialCount: Int { get }
    
    /// Identify whether or not a credential is currently cached for the supplied token.
    /// - Parameter token: Token to identify a credential instance for.
    /// - Returns: `true` if this datasource has a cached credential.
    func hasCredential(for token: Token) -> Bool
    
    /// Returns a credential for the given token.
    ///
    /// The implementation should ensure that no duplicate user instances should be created for the given token. It is recommended that the method be threadsafe as well.
    /// - Returns: Credential for the given token, either newly-created or previously cached.
    func credential(for token: Token, coordinator: CredentialCoordinator) -> Credential
    
    /// Removes the given credential from the datasource.
    ///
    /// Credential instances may later be recreated when the ``credential(for:coordinator:)`` method is invoked.
    func remove(credential: Credential)
}
