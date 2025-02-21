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

fileprivate typealias Configuration = OAuth2Client.Configuration

/// Initializers consuming ``OAuth2Client/PropertyListConfiguration``
@_documentation(visibility: internal)
extension OAuth2Client {
    @_documentation(visibility: internal)
    @inlinable
    public convenience init(_ config: OAuth2Client.PropertyListConfiguration) throws {
        self.init(try Configuration(plist: config))
    }
}

/// Initializers for accepting client configuration using an Issuer URL.
@_documentation(visibility: internal)
extension OAuth2Client {
    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - issuerURL: Issuer URL to use for interactions with the OAuth2 authorization server.
    ///   - clientId: The unique client ID representing this client.
    ///   - scope: The array of OAuth2 scopes requested for this client.
    ///   - redirectUri: Optional `redirect_uri` value for this client.
    ///   - logoutRedirectUri: Optional `logout_redirect_uri` value for this client.
    ///   - authentication: The client authentication  model to use (Default: ``OAuth2Client/ClientAuthentication/none``)
    ///   - session: Optional URLSession to use for network requests.
    @inlinable
    public convenience init(issuerURL: URL,
                            discoveryURL: URL? = nil,
                            clientId: String,
                            scope: some WhitespaceSeparated,
                            redirectUri: URL? = nil,
                            logoutRedirectUri: URL? = nil,
                            authentication: ClientAuthentication = .none,
                            session: URLSessionProtocol? = nil)
    {
        self.init(Configuration(issuerURL: issuerURL,
                                discoveryURL: discoveryURL,
                                clientId: clientId,
                                scope: scope.whitespaceSeparated,
                                redirectUri: redirectUri,
                                logoutRedirectUri: logoutRedirectUri,
                                authentication: authentication),
                  session: session)
    }
}
