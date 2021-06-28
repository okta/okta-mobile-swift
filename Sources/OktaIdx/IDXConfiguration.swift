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

extension IDXClient {
    /// Configuration options for an IDXClient.
    ///
    /// This class is used to define the configuration, as defined in your Okta application settings, that will be used to interact with the Okta Identity Engine API.
    @objc(IDXClientConfiguration)
    public final class Configuration: NSObject, Codable {
        /// The issuer URL.
        @objc public let issuer: String
        
        /// The application's client ID.
        @objc public let clientId: String
        
        /// The application's client secret, if required.
        @objc public let clientSecret: String?
        
        /// The access scopes required by the client.
        @objc public let scopes: [String]
        
        /// The application's redirect URI.
        @objc public let redirectUri: String

        /// Initializes an IDX configuration object.
        /// - Parameters:
        ///   - issuer: The issuer URL.
        ///   - clientId: The application's client ID.
        ///   - clientSecret: The application's client secret, if required.
        ///   - scopes: The application's access scopes.
        ///   - redirectUri: The application's redirect URI.
        @objc public init(issuer: String,
                          clientId: String,
                          clientSecret: String?,
                          scopes: [String],
                          redirectUri: String)
        {
            self.issuer = issuer
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.scopes = scopes
            self.redirectUri = redirectUri
            
            super.init()
        }
    }
}
