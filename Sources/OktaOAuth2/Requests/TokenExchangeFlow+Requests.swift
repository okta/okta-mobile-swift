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

import AuthFoundation
import Foundation

extension TokenExchangeFlow {
    /// Types specify token's identity.
    public enum TokenType {
        /// Describes specific token used by ``TokenExchangeFlow/TokenType``.
        public enum Kind: String {
            case idToken = "id_token"
            case accessToken = "access_token"
            case deviceSecret = "device-secret"
            case refreshToken = "refresh_token"
        }
        
        /// A security token that represents the identity of the acting party.
        case actor(type: Kind, value: String)
        /// A security token that represents the identity of the party on behalf of whom the request is being made.
        case subject(type: Kind, value: String)
        
        private var name: String {
            switch self {
            case .actor:
                return "actor"
            case .subject:
                return "subject"
            }
        }
        
        var key: String { name + "_token" }
        var keyType: String { key + "_type" }
        
        var urn: String {
            switch self {
            case let .actor(tokenType, _):
                return "urn:x-oath:params:oauth:token-type:\(tokenType.rawValue)"
            case let .subject(tokenType, _):
                return "urn:ietf:params:oauth:token-type:\(tokenType.rawValue)"
            }
        }
        
        var value: String {
            switch self {
            case let .actor(_, value):
                return value
            case let .subject(_, value):
                return value
            }
        }
    }
}

extension TokenExchangeFlow {
    struct TokenRequest {
        let openIdConfiguration: OpenIdConfiguration
        let clientId: String
        let tokens: [TokenType]
        let scope: String
        let audience: String
        let grantType = GrantType.tokenExchange
    }
}

extension TokenExchangeFlow.TokenRequest: OAuth2TokenRequest, OAuth2APIRequest, APIRequestBody {
    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.tokenEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        let tokensDict = tokens.map { token in
            [
                token.key: token.value,
                token.keyType: token.urn
            ]
        }.flatMap { $0 }
        
        return [
            "client_id": clientId,
            "grant_type": grantType.rawValue,
            "scope": scope,
            "audience": audience
        ].merging(tokensDict) { _, new in new }
    }
}
