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

public extension Token {
    /// The possible token types that can be revoked.
    enum RevokeType {
        /// Indicates the access token should be revoked.
        case accessToken
        
        /// Indicates the refresh token should be revoked, if one is present. This will result in the access token being revoked as well.
        case refreshToken
        
        /// Indicates the device secret should be revoked.
        case deviceSecret
        
        /// Indicates that all tokens should be revoked.
        case all
    }
    
    /// The kind of access token an operation should be used with.
    enum Kind: String {
        /// Indicates the access token.
        case accessToken = "access_token"
        
        /// Indicates the refresh token.
        case refreshToken = "refresh_token"
        
        /// Indicates the ID token.
        case idToken = "id_token"
        
        /// Indicates the device secret.
        case deviceSecret = "device_secret"
    }
}
