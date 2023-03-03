//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import AuthFoundation

extension JWTBearerFlow {
    struct TokenRequest {
        let openIdConfiguration: OpenIdConfiguration
        let clientId: String
        let clientSecret: String?
        let scope: String
        let assertion: String
    }
}

extension JWTBearerFlow.TokenRequest: OAuth2TokenRequest, OAuth2APIRequest, APIRequestBody, APIParsingContext {
    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.tokenEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        var result = [
            "client_id": clientId,
            "scope": scope,
            "grant_type": GrantType.jwtBearer.rawValue,
            "assertion": assertion
        ]
        
        if let clientSecret = clientSecret {
            result["client_secret"] = clientSecret
        }
        
        return result
    }
    
    var codingUserInfo: [CodingUserInfoKey: Any]? {
        [
            .clientSettings: [
                "client_id": clientId,
                "scope": scope
            ]
        ]
    }
}
