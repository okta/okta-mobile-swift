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

/// Protocol that a custom ``CredentialDataSource`` instances are required to communicate changes to.
public protocol CredentialDataSourceDelegate: AnyObject {
    /// Sent when a new credential is created.
    ///
    /// This is usually sent in response to the ``CredentialDataSource/credential(for:coordinator:)`` method, but in any other circumstance where a credential is created, this message should be sent.
    func credential(dataSource: CredentialDataSource, created credential: Credential)
    
    /// Sent when an existing credential is removed from the data source cache.
    ///
    /// The credential may be re-created at a later date, if its token has not been removed from the ``TokenStorage``. This message is only to indicate that the credential has been removed from the data source cache.
    func credential(dataSource: CredentialDataSource, removed credential: Credential)
}
