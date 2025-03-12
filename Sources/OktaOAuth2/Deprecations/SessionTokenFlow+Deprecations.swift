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

#if canImport(UIKit) || canImport(AppKit)
import Foundation

extension SessionTokenFlow {
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "init(issuerURL:clientId:scope:redirectUri:additionalParameters:)")
    public init(issuer: URL,
                clientId: String,
                scopes: String,
                redirectUri: URL,
                additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        try self.init(issuerURL: issuer, clientId: clientId, scope: scopes, redirectUri: redirectUri, additionalParameters: additionalParameters)
    }

    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "init(client:additionalParameters:)")
    public init(redirectUri: URL,
                additionalParameters: [String: any APIRequestArgument]? = nil,
                client: OAuth2Client) throws
    {
        var configuration = client.configuration
        configuration.redirectUri = redirectUri

        try self.init(client: OAuth2Client(configuration, session: client.session),
                      additionalParameters: additionalParameters)
    }
}

extension OAuth2Client {
    @_documentation(visibility: private)
    @available(*, deprecated, renamed: "sessionTokenFlow(additionalParameters:)")
    public func sessionTokenFlow(redirectUri: URL,
                                 additionalParameters: [String: String]? = nil) throws -> SessionTokenFlow
    {
        var configuration = configuration
        configuration.redirectUri = redirectUri
        return try SessionTokenFlow(client: OAuth2Client(configuration, session: session),
                                    additionalParameters: additionalParameters)
    }
}
#endif
