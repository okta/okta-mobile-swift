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
extension Token {
    struct RevokeRequest {
        let openIdConfiguration: OpenIdConfiguration
        let token: String
        let hint: Token.Kind?
        let configuration: [String: String]
    }

    struct RefreshRequest {
        let openIdConfiguration: OpenIdConfiguration
        let token: Token
        let configuration: [String: String]
    }
    
    struct IntrospectRequest {
        let openIdConfiguration: OpenIdConfiguration
        let token: Token
        let type: Token.Kind
    }
}

extension Token: APIAuthorization {
    public var authorizationHeader: String? { "\(tokenType) \(accessToken)" }
}

/// Sub-protocol of ``APIRequest`` used to define requests that are performed using links supplied via an organization's ``OpenIdConfiguration``.
public protocol OAuth2APIRequest: APIRequest {
    /// The ``OpenIdConfiguration`` used to formulate this request's ``APIRequest/url``.
    var openIdConfiguration: OpenIdConfiguration { get }
}

extension Token.RevokeRequest: OAuth2APIRequest, APIRequestBody {
    typealias ResponseType = Empty
    
    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.revocationEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        var result = configuration
        result["token"] = token
        
        if let hint = hint {
            result["token_type_hint"] = hint.rawValue
        }
        
        return result
    }
}

extension Token.IntrospectRequest: OAuth2APIRequest, APIRequestBody {
    typealias ResponseType = TokenInfo

    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.introspectionEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var authorization: APIAuthorization? { token }
    var bodyParameters: [String: Any]? {
        [
            "token": (token.token(of: type) ?? "") as String,
            "token_type_hint": type.rawValue
        ]
    }
}

extension Token.RefreshRequest: OAuth2APIRequest, APIRequestBody, APIParsingContext {
    typealias ResponseType = Token

    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.tokenEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        guard let refreshToken = token.refreshToken else { return nil }

        var result = configuration
        result["grant_type"] = "refresh_token"
        result["refresh_token"] = refreshToken
        
        return result
    }
    
    var codingUserInfo: [CodingUserInfoKey: Any]? {
        guard let clientSettings = token.context.clientSettings,
              let settings = clientSettings.reduce(into: [:], { partialResult, item in
            guard let key = CodingUserInfoKey(rawValue: item.key) else { return }
            partialResult?[key] = item.value
        }) else { return nil }
        
        return [
            .clientSettings: settings,
            .tokenId: token.id
        ]
    }
}
