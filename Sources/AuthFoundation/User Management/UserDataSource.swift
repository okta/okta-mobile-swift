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

/// Protocol that enables a developer to interact with, and override, the default behavior for the lifecycle of ``User`` instances.
public protocol UserDataSource {
    /// Mandatory delegate property that is used to communicate when users within this data source are created or changed.
    var delegate: UserDataSourceDelegate? { get set }

    /// Enables develoeprs to provide a custom URLSession when a user manager is created for the given token.
    /// - Returns: URLSession to be used for this token, or `nil` to accept the default behavior.
    func urlSession(for token: Token) -> URLSessionProtocol
    
    /// Returns the number of user objects currently cached within this datasource.
    ///
    /// > Note: This should not return the total number of available tokens, but rather the number of user objects loaded within this cache.
    var userCount: Int { get }
    
    /// Returns a user for the given token.
    ///
    /// The implementation should ensure that no duplicate user instances should be created for the given token. It is recommended that the method be threadsafe as well.
    /// - Returns: User for the given token, either newly-created or previously cached.
    func user(for token: Token) -> User
    
    /// Removes the given user from the datasource.
    ///
    /// User instances may later be recreated when the ``user(for:)`` method is invoked.
    func remove(user: User)
}

public protocol UserDataSourceDelegate: AnyObject {
    func user(dataSource: UserDataSource, created user: User)
    func user(dataSource: UserDataSource, removed user: User)
    func user(dataSource: UserDataSource, updated user: User)
}

extension UserDataSource {
    public func urlSession(for token: Token) -> URLSessionProtocol {
        URLSession(configuration: .ephemeral)
    }
}
