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
    public struct Configuration: Codable, Equatable, Hashable, ProvidesOAuth2Parameters {
        /// The base URL for interactions with this OAuth2 server.
        public var issuerURL: URL
        
        /// The discovery URL used to retrieve the ``OpenIdConfiguration`` for this client.
        public var discoveryURL: URL
        
        /// The unique client ID representing this ``OAuth2Client``.
        public var clientId: String
        
        /// The list of OAuth2 scopes requested for this client.
        public var scope: String
        
        /// The Redirect URI, if this client configuration requires it.
        public var redirectUri: URL?
        
        /// The Logout Redirect URI, if this client configuration requires it.
        public var logoutRedirectUri: URL?

        /// The type of authentication this client will perform when interacting with the authorization server.
        public var authentication: ClientAuthentication
        
        /// Initializer for constructing an OAuth2Client.
        /// - Parameters:
        ///   - issuerURL: Issuer URL for this client configuration.
        ///   - discoveryURL: Discovery URL, or `nil` to accept the default OpenIDConfiguration endpoint.
        ///   - clientId: The client ID.
        ///   - scope: The list of OAuth2 scopes.
        ///   - redirectUri: Optional `redirect_uri` value for this client.
        ///   - logoutRedirectUri: Optional `logout_redirect_uri` value for this client.
        ///   - authentication: The client authentication  model to use (Default: ``OAuth2Client/ClientAuthentication/none``)
        public init(issuerURL: URL,
                    discoveryURL: URL? = nil,
                    clientId: String,
                    scope: String,
                    redirectUri: URL? = nil,
                    logoutRedirectUri: URL? = nil,
                    authentication: ClientAuthentication = .none)
        {
            var relativeURL = issuerURL
            
            // Ensure the base URL contains a trailing slash in its path, so request paths can be safely appended.
            if !relativeURL.lastPathComponent.isEmpty {
                relativeURL = relativeURL.appendingComponent("")
            }
            
            self.issuerURL = issuerURL
            self.discoveryURL = discoveryURL ?? relativeURL.appendingComponent(".well-known/openid-configuration")
            self.clientId = clientId
            self.scope = scope
            self.redirectUri = redirectUri
            self.logoutRedirectUri = logoutRedirectUri
            self.authentication = authentication
        }
        
        /// Convenience initializer to create a client using a simple domain name.
        /// - Parameters:
        ///   - domain: Domain name for the OAuth2 client.
        ///   - clientId: The client ID.
        ///   - scope: The list of OAuth2 scopes.
        ///   - redirectUri: Optional `redirect_uri` value for this client.
        ///   - logoutRedirectUri: Optional `logout_redirect_uri` value for this client.
        ///   - authentication: The client authentication  model to use (Default: ``OAuth2Client/ClientAuthentication/none``)
        public init(domain: String,
                    clientId: String,
                    scope: String,
                    redirectUri: String? = nil,
                    logoutRedirectUri: String? = nil,
                    authentication: ClientAuthentication = .none) throws
        {
            self.init(issuerURL: try URL(requiredString: "https://\(domain)"),
                      clientId: clientId,
                      scope: scope,
                      redirectUri: try URL(string: redirectUri),
                      logoutRedirectUri: try URL(string: logoutRedirectUri),
                      authentication: authentication)
        }

        @_documentation(visibility: private)
        public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
            var result = authentication.parameters(for: category) ?? [:]
            
            switch category {
            case .authorization, .token:
                result["scope"] = scope
                result["client_id"] = clientId
                result["redirect_uri"] = redirectUri
            case .configuration, .resource, .other: break
            }
            
            return result.compactMapValues { $0 }
        }
    }
}

fileprivate extension OAuth2Client.Configuration {
    enum CodingKeysV1: String, CodingKey, CaseIterable {
        case baseURL
        case discoveryURL
        case clientId
        case scopes
        case authentication
    }

    enum CodingKeysV2: String, CodingKey, CaseIterable {
        case issuerURL
        case discoveryURL
        case redirectUri
        case logoutRedirectUri
        case clientId
        case scope
        case authentication
    }
}

extension OAuth2Client.Configuration {
    @_documentation(visibility: private)
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeysV1.self),
           container.allKeys.contains(.baseURL)
        {
            self.init(issuerURL: try container.decode(URL.self, forKey: .baseURL),
                      discoveryURL: try container.decodeIfPresent(URL.self, forKey: .discoveryURL),
                      clientId: try container.decode(String.self, forKey: .clientId),
                      scope: try container.decode(String.self, forKey: .scopes),
                      authentication: try container.decodeIfPresent(OAuth2Client.ClientAuthentication.self, forKey: .authentication) ?? .none)
        }

        else if let container = try? decoder.container(keyedBy: CodingKeysV2.self) {
            self.init(issuerURL: try container.decode(URL.self, forKey: .issuerURL),
                      discoveryURL: try container.decodeIfPresent(URL.self, forKey: .discoveryURL),
                      clientId: try container.decode(String.self, forKey: .clientId),
                      scope: try container.decode(String.self, forKey: .scope),
                      redirectUri: try container.decodeIfPresent(URL.self, forKey: .redirectUri),
                      logoutRedirectUri: try container.decodeIfPresent(URL.self, forKey: .logoutRedirectUri),
                      authentication: try container.decodeIfPresent(OAuth2Client.ClientAuthentication.self, forKey: .authentication) ?? .none)
        }
        
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Unsupported OAuth 2.0 configuration version"))
        }
    }
    
    @_documentation(visibility: private)
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeysV2.self)
        try container.encode(issuerURL, forKey: .issuerURL)
        try container.encode(discoveryURL, forKey: .discoveryURL)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(scope, forKey: .scope)
        try container.encodeIfPresent(redirectUri, forKey: .redirectUri)
        try container.encodeIfPresent(logoutRedirectUri, forKey: .logoutRedirectUri)
        try container.encode(authentication, forKey: .authentication)
    }
}

extension OAuth2Client.Configuration: APIClientConfiguration {
    @_documentation(visibility: private)
    public var baseURL: URL { issuerURL }
}
