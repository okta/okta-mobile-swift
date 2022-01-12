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
        let token: String
        let hint: Token.Kind?
    }

    struct RefreshRequest {
        let token: Token
        let configuration: [String:String]
    }
    
    struct IntrospectRequest {
        let token: Token
        let type: Token.Kind
    }
}

extension Token: APIAuthorization {
    public var authorizationHeader: String? { "\(tokenType) \(accessToken)" }
}

extension Token.RevokeRequest: APIRequest, APIRequestBody {
    var httpMethod: APIRequestMethod { .post }
    var path: String { "v1/revoke" }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String : Any]? {
        var result = [
            "token": token
        ]
        
        if let hint = hint {
            result["token_type_hint"] = hint.rawValue
        }
        
        return result
    }
}

extension Token.IntrospectRequest: APIRequest, APIRequestBody {
    var httpMethod: APIRequestMethod { .post }
    var path: String { "v1/introspect" }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var authorization: APIAuthorization? { token }
    var bodyParameters: [String : Any]? {
        [
            "token": (token.token(of: type) ?? "") as String,
            "token_type_hint": type.rawValue
        ]
    }
}

extension Token.RefreshRequest: APIRequest, APIRequestBody {
    var httpMethod: APIRequestMethod { .post }
    var path: String { "v1/token" }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String : Any]? {
        guard let refreshToken = token.refreshToken else { return nil }

        var result = configuration
        result["grant_type"] = "refresh_token"
        result["refresh_token"] = refreshToken
        
        return result
    }
}
