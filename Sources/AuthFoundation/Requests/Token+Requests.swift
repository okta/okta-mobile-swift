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
        let clientAuthentication: OAuth2Client.ClientAuthentication
        let url: URL
        let token: String
        let hint: Token.Kind?
        let configuration: [String: String]
        
        init(openIdConfiguration: OpenIdConfiguration,
             clientAuthentication: OAuth2Client.ClientAuthentication,
             token: String,
             hint: Token.Kind?,
             configuration: [String: String]) throws
        {
            self.openIdConfiguration = openIdConfiguration
            self.clientAuthentication = clientAuthentication
            self.token = token
            self.hint = hint
            self.configuration = configuration

            guard let url = openIdConfiguration.revocationEndpoint else {
                throw OAuth2Error.missingOpenIdConfiguration(attribute: "revocation_endpoint")
            }
            self.url = url
        }
    }

    struct RefreshRequest {
        let openIdConfiguration: OpenIdConfiguration
        let resource: String
        let clientSecret: String
        let clientConfiguration: OAuth2Client.Configuration
        let refreshToken: String
        let id: String
        let configuration: [String: String]
        
        static let placeholderId = "temporary_id"
    }
    
    struct IntrospectRequest {
        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let token: Token
        let type: Token.Kind
        let url: URL
        
        init(openIdConfiguration: OpenIdConfiguration,
             clientConfiguration: OAuth2Client.Configuration,
             token: Token,
             type: Token.Kind) throws
        {
            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
            self.token = token
            self.type = type
            
            guard let url = openIdConfiguration.introspectionEndpoint else {
                throw OAuth2Error.missingOpenIdConfiguration(attribute: "introspection_endpoint")
            }
            self.url = url
        }
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
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        var result = configuration
        result["token"] = token
        
        if let hint = hint {
            result["token_type_hint"] = hint.rawValue
        }
        
        if let parameters = clientAuthentication.additionalParameters {
            result.merge(parameters, uniquingKeysWith: { $1 })
        }

        return result
    }
}

extension Token.IntrospectRequest: OAuth2APIRequest, APIRequestBody {
    typealias ResponseType = TokenInfo

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var authorization: APIAuthorization? { nil }
    var bodyParameters: [String: Any]? {
        var result = [
            "token": (token.token(of: type) ?? "") as String,
            "client_id": token.context.configuration.clientId,
            "token_type_hint": type.rawValue
        ]
        
        if let parameters = clientConfiguration.authentication.additionalParameters {
            result.merge(parameters, uniquingKeysWith: { $1 })
        }

        return result
    }
}

extension Token.RefreshRequest: OAuth2APIRequest, APIRequestBody, APIParsingContext, OAuth2TokenRequest {
    typealias ResponseType = Token

    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.tokenEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var clientId: String { clientConfiguration.clientId }
    var bodyParameters: [String: Any]? {
        var result = configuration
        result["grant_type"] = "refresh_token"
        result["refresh_token"] = refreshToken
        result["resource"] = resource
        result["client_secret"] = clientSecret

        if let parameters = clientConfiguration.authentication.additionalParameters {
            result.merge(parameters, uniquingKeysWith: { $1 })
        }

        return result
    }
    
    var codingUserInfo: [CodingUserInfoKey: Any]? {
        guard let settings = configuration.reduce(into: [:], { partialResult, item in
            guard let key = CodingUserInfoKey(rawValue: item.key) else { return }
            partialResult?[key] = item.value
        }) else { return nil }
        
        var result: [CodingUserInfoKey: Any] = [
            .clientSettings: settings
        ]
        
        if id != Self.placeholderId {
            result[.tokenId] = id
        }
        
        return result
    }
}
