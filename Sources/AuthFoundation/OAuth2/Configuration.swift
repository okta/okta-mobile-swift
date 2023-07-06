//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension OAuth2Client {
    /// The configuration for an ``OAuth2Client``.
    ///
    /// This defines the basic information necessary for interacting with an OAuth2 authorization server.
    public final class Configuration: Codable, Equatable, Hashable, APIClientConfiguration {
        /// The base URL for interactions with this OAuth2 server.
        public let baseURL: URL
        
        /// The discovery URL used to retrieve the ``OpenIdConfiguration`` for this client.
        public let discoveryURL: URL
        
        /// The unique client ID representing this ``OAuth2Client``.
        public let clientId: String
        
        /// The list of OAuth2 scopes requested for this client.
        public let scopes: String
        
        /// The type of authentication this client will perform when interacting with the authorization server.
        public let authentication: ClientAuthentication
        
        /// Initializer for constructing an OAuth2Client.
        /// - Parameters:
        ///   - baseURL: Base URL.
        ///   - discoveryURL: Discovery URL, or `nil` to accept the default OpenIDConfiguration endpoint.
        ///   - clientId: The client ID.
        ///   - scopes: The list of OAuth2 scopes.
        ///   - authentication: The client authentication  model to use (Default: `.none`)
        public init(baseURL: URL,
                    discoveryURL: URL? = nil,
                    clientId: String,
                    scopes: String,
                    authentication: ClientAuthentication = .none)
        {
            var relativeURL = baseURL
            
            // Ensure the base URL contains a trailing slash in its path, so request paths can be safely appended.
            if !relativeURL.lastPathComponent.isEmpty {
                relativeURL.appendPathComponent("")
            }
            
            self.baseURL = baseURL
            self.discoveryURL = discoveryURL ?? relativeURL.appendingPathComponent(".well-known/openid-configuration")
            self.clientId = clientId
            self.scopes = scopes
            self.authentication = authentication
        }
        
        /// Convenience initializer to create a client using a simple domain name.
        /// - Parameters:
        ///   - domain: Domain name for the OAuth2 client.
        ///   - clientId: The client ID.
        ///   - scopes: The list of OAuth2 scopes.
        ///   - authentication: The client authentication  model to use (Default: `.none`)
        public convenience init(domain: String,
                                clientId: String,
                                scopes: String,
                                authentication: ClientAuthentication = .none) throws
        {
            guard let url = URL(string: "https://\(domain)") else {
                throw OAuth2Error.invalidUrl
            }
            
            self.init(baseURL: url, clientId: clientId, scopes: scopes, authentication: authentication)
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.baseURL = try container.decode(URL.self, forKey: .baseURL)
            self.discoveryURL = try container.decode(URL.self, forKey: .discoveryURL)
            self.clientId = try container.decode(String.self, forKey: .clientId)
            self.scopes = try container.decode(String.self, forKey: .scopes)
            self.authentication = try container.decodeIfPresent(OAuth2Client.ClientAuthentication.self, forKey: .authentication) ?? .none
        }
        
        public static func == (lhs: OAuth2Client.Configuration, rhs: OAuth2Client.Configuration) -> Bool {
            lhs.baseURL == rhs.baseURL &&
            lhs.clientId == rhs.clientId &&
            lhs.scopes == rhs.scopes &&
            lhs.authentication == rhs.authentication
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(baseURL)
            hasher.combine(clientId)
            hasher.combine(scopes)
            hasher.combine(authentication)
        }
    }
}
