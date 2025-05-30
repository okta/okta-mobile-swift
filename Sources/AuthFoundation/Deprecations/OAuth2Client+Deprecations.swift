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

extension OAuth2Client {
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "init(domain:clientId:scope:redirectUri:logoutRedirectUri:authentication:session:)")
    public convenience init(domain: String,
                            clientId: String,
                            scopes: String,
                            authentication: ClientAuthentication = .none,
                            session: (any URLSessionProtocol)? = nil) throws
    {
        self.init(try Configuration(domain: domain,
                                    clientId: clientId,
                                    scope: scopes,
                                    authentication: authentication),
                  session: session)
    }
    
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "init(issuerURL:clientId:scope:redirectUri:logoutRedirectUri:authentication:session:)")
    public convenience init(baseURL: URL,
                            clientId: String,
                            scopes: String,
                            authentication: ClientAuthentication = .none,
                            session: (any URLSessionProtocol)? = nil)
    {
        self.init(Configuration(issuerURL: baseURL,
                                clientId: clientId,
                                scope: scopes,
                                authentication: authentication),
                  session: session)
    }
}
