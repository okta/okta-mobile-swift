//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Convenience initializers that accept alternate argument types for developer convenience.
@_documentation(visibility: private)
extension OAuth2Client.Configuration {
    @_documentation(visibility: private)
    @inlinable
    public init(issuerURL: URL,
                discoveryURL: URL? = nil,
                clientId: String,
                scope: some WhitespaceSeparated,
                redirectUri: URL? = nil,
                logoutRedirectUri: URL? = nil,
                authentication: OAuth2Client.ClientAuthentication = .none)
    {
        self.init(issuerURL: issuerURL,
                  discoveryURL: discoveryURL,
                  clientId: clientId,
                  scope: .init(wrappedValue: scope.whitespaceSeparated),
                  redirectUri: redirectUri,
                  logoutRedirectUri: logoutRedirectUri,
                  authentication: authentication)
    }

    @_documentation(visibility: private)
    @inlinable
    public init(domain: String,
                discoveryURL: URL? = nil,
                clientId: String,
                scope: some WhitespaceSeparated,
                redirectUri: String? = nil,
                logoutRedirectUri: String? = nil,
                authentication: OAuth2Client.ClientAuthentication = .none) throws
    {
        self.init(issuerURL: try URL(requiredString: "https://\(domain)"),
                  discoveryURL: discoveryURL,
                  clientId: clientId,
                  scope: .init(wrappedValue: scope.whitespaceSeparated),
                  redirectUri: try URL(string: redirectUri),
                  logoutRedirectUri: try URL(string: logoutRedirectUri),
                  authentication: authentication)
    }
    
    @_documentation(visibility: private)
    @inlinable
    public init(plist config: OAuth2Client.PropertyListConfiguration) throws {
        self.init(issuerURL: config.issuerURL,
                  clientId: config.clientId,
                  scope: .init(wrappedValue: config.scope),
                  redirectUri: config.redirectUri,
                  logoutRedirectUri: config.logoutRedirectUri,
                  authentication: config.authentication)
    }
}
