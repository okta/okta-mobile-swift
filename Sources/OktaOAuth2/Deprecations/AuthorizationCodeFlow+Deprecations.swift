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

extension AuthorizationCodeFlow {
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "init(issuerURL:clientId:scope:redirectUri:additionalParameters:)")
    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            redirectUri: URL,
                            additionalParameters: [String: APIRequestArgument]? = nil)
    {
        fatalError()
    }
    
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "init(client:additionalParameters:)")
    public convenience init(redirectUri: URL,
                additionalParameters: [String: APIRequestArgument]?,
                client: OAuth2Client)
    {
        fatalError()
    }
    
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "start(with:completion:)")
    public func start(with context: Context? = nil,
                      additionalParameters: [String: String]?,
                      completion: @escaping (Result<URL, OAuth2Error>) -> Void)
    {
        fatalError()
    }

    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "start(with:)")
    public func start(with context: Context?, additionalParameters: [String: String]?) async throws -> URL
    {
        fatalError()
    }
}

extension OAuth2Client {
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "authorizationCodeFlow(additionalParameters:)")
    public func authorizationCodeFlow(
        redirectUri: URL,
        additionalParameters: [String: String]?) -> AuthorizationCodeFlow
    {
        fatalError()
    }
}
