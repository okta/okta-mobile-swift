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

/// Represents the class that manages the relationship between ``TokenStorage`` and ``CredentialDataSource`` instances.
@CredentialActor
public protocol CredentialCoordinator: AnyObject, Sendable {
    var credentialDataSource: any CredentialDataSource { get set }
    var tokenStorage: any TokenStorage { get set }
    
    func observe(oauth2 client: OAuth2Client)
    func remove(credential: Credential) throws
}
