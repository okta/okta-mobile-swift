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

extension AuthorizationSSOFlow {
    struct TokenRequest {
        enum Token: String {
            case actor
            case subject
            
            var key: String { rawValue + "_token" }
            var keyType: String { key + "_type" }
            
            var keyTypeValue: String {
                switch self {
                case .actor:
                    return "urn:x-oath:params:oauth:token-type:device-secret"
                case .subject:
                    return "urn:ietf:params:oauth:token-type:id_token"
                }
            }
        }
        
        let clientId: String
        let deviceSecret: String
        let idToken: String
        let scope: String
        let audience: String
        let grantType = GrantType.other("urn:ietf:params:oauth:grant-type:token-exchange")
        let tokenPath: String
    }
}

extension AuthorizationSSOFlow.TokenRequest: TokenRequest, APIRequest, APIRequestBody {
    var httpMethod: APIHTTPMethod { .post }
    var path: String { tokenPath }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        [
            "client_id": clientId,
            "grant_type": grantType.rawValue,
            Token.actor.key: deviceSecret,
            Token.actor.keyType: Token.actor.keyTypeValue,
            Token.subject.key: idToken,
            Token.subject.keyType: Token.subject.keyTypeValue,
            "scope": scope,
            "audience": audience
        ]
    }
}

