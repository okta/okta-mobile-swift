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
        let clientConfiguration: OAuth2Client.Configuration
        let url: URL
        let token: String
        let hint: Token.Kind?
        let configuration: [String: APIRequestArgument]
        
        init(openIdConfiguration: OpenIdConfiguration,
             clientConfiguration: OAuth2Client.Configuration,
             token: String,
             hint: Token.Kind?,
             configuration: [String: APIRequestArgument]) throws
        {
            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
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
        let clientConfiguration: OAuth2Client.Configuration
        let refreshToken: String
        let scope: String?
        let id: String
        
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
    /// The client's Open ID Configuration object defining the settings and endpoints used to interact with this Authorization Server.
    var openIdConfiguration: OpenIdConfiguration { get }

    /// The category for the request being made, which can be used to determine which arguments are included.
    var category: OAuth2APIRequestCategory { get }
}

/// Protocol used by requests that are initiated by a class conforming to ``AuthenticationFlow``.
///
/// Some authentication flows consist of multiple requests, and as a result critical context information that is important for response parsing and object persistence may not be available on the final request. This object enables the context from the flow to be made available to the API request and response parsing lifecycle.
public protocol AuthenticationFlowRequest {
    associatedtype Flow: AuthenticationFlow
    
    /// The authentication flow's ``AuthenticationContext`` instance that created this request.
    var context: Flow.Context { get }
}

/// Categorizes the types of requests made to an authorization server.
public enum OAuth2APIRequestCategory: CaseIterable {
    /// Requests used for discovery of an authorization server's configuration
    case configuration
    
    /// Initiates an authorization workflow.
    case authorization
    
    /// Requests a token from an authorization server.
    case token
    
    /// Perform a resource server request using an access token.
    case resource
    
    /// Other uncategorized requests.
    case other
}

extension Token.RevokeRequest: OAuth2APIRequest, APIRequestBody {
    typealias ResponseType = Empty
    
    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var category: OAuth2APIRequestCategory { .other }
    var bodyParameters: [String: APIRequestArgument]? {
        var result = configuration
        result["token"] = token
        result["client_id"] = clientConfiguration.clientId
        
        if let hint = hint {
            result["token_type_hint"] = hint
        }
        
        result.merge(clientConfiguration.authentication.parameters(for: category))

        return result
    }
}

extension Token.IntrospectRequest: OAuth2APIRequest, APIRequestBody {
    typealias ResponseType = TokenInfo

    var httpMethod: APIRequestMethod { .post }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var authorization: APIAuthorization? { nil }
    var category: OAuth2APIRequestCategory { .other }
    var bodyParameters: [String: APIRequestArgument]? {
        var result: [String: APIRequestArgument] = [
            "token": token.token(of: type) ?? "",
            "client_id": token.context.configuration.clientId,
            "token_type_hint": type
        ]
        
        result.merge(clientConfiguration.parameters(for: category))

        return result
    }
}

extension Token.RefreshRequest: OAuth2APIRequest, APIRequestBody, APIParsingContext, OAuth2TokenRequest {
    typealias ResponseType = Token

    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.tokenEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var category: OAuth2APIRequestCategory { .token }
    var tokenValidatorContext: any IDTokenValidatorContext { NullIDTokenValidatorContext }
    var bodyParameters: [String: APIRequestArgument]? {
        var result: [String: any APIRequestArgument] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ]
        result.merge(clientConfiguration.parameters(for: category))

        if let scope = scope {
            result["scope"] = scope
        } else {
            result.removeValue(forKey: "scope")
        }

        return result
    }
    
    var codingUserInfo: [CodingUserInfoKey: Any]? {
        if id != Self.placeholderId {
            return [.tokenId: id]
        }
        
        return nil
    }
}
