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

/// Describes the configuration of an OpenID server.
///
/// The values exposed from this configuration are typically used during authentication, or when querying a server for its capabilities.
public struct OpenIdConfiguration: Codable, JSONDecodable {
    public let authorizationEndpoint: URL
    public let endSessionEndpoint: URL?
    public let introspectionEndpoint: URL?
    public let deviceAuthorizationEndpoint: URL?
    public let issuer: URL
    public let jwksUri: URL
    public let registrationEndpoint: URL?
    public let revocationEndpoint: URL
    public let tokenEndpoint: URL
    public let userinfoEndpoint: URL?
    public let scopesSupported: [String]?
    public let responseTypesSupported: [String]
    public let responseModesSupported: [String]?
    public let claimsSupported: [Claim]
    public let grantTypesSupported: [GrantType]?
    public let subjectTypesSupported: [String]

    public static let jsonDecoder: JSONDecoder = {
        let result = JSONDecoder()
        result.keyDecodingStrategy = .convertFromSnakeCase
        return result
    }()
}
