//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct TokenRequest {
    let openIdConfiguration: OpenIdConfiguration
    let clientId: String
    let scope: String
    let loginHint: String?
    let factor: any AuthenticationFactor
    let mfaToken: String?
    let oobCode: String?
    let grantTypesSupported: [GrantType]?
    
    init(openIdConfiguration: OpenIdConfiguration,
         clientId: String,
         scope: String,
         loginHint: String? = nil,
         factor: any AuthenticationFactor,
         mfaToken: String? = nil,
         oobCode: String? = nil,
         grantTypesSupported: [GrantType]? = nil)
    {
        self.openIdConfiguration = openIdConfiguration
        self.clientId = clientId
        self.scope = scope
        self.loginHint = loginHint
        self.factor = factor
        self.mfaToken = mfaToken
        self.oobCode = oobCode
        self.grantTypesSupported = grantTypesSupported
    }
}

extension TokenRequest: OAuth2TokenRequest, OAuth2APIRequest, APIRequestBody {
    var httpMethod: APIRequestMethod { .post }
    var url: URL { openIdConfiguration.tokenEndpoint }
    var contentType: APIContentType? { .formEncoded }
    var acceptsType: APIContentType? { .json }
    var bodyParameters: [String: Any]? {
        var result: [String: Any] = [
            "client_id": clientId,
            "grant_type": factor.grantType.rawValue,
            "scope": scope
        ]
        
        if let mfaToken = mfaToken {
            result["mfa_token"] = mfaToken
        }
        
        if let oobCode = oobCode {
            result["oob_code"] = oobCode
        }
        
        if let loginHint = loginHint {
            let key: String
            if let factor = factor as? DirectAuthenticationFlow.PrimaryFactor {
                key = factor.loginHintKey
            } else {
                key = "login_hint"
            }
            result[key] = loginHint
        }
        
        if let grantTypesSupported = grantTypesSupported?.map({ $0.rawValue }) {
            result["grant_types_supported"] = grantTypesSupported.joined(separator: " ")
        }
        
        if let parameters = factor.tokenParameters {
            result.merge(parameters) { _, new in
                new
            }
        }
        
        return result
    }
}

extension TokenRequest: APIParsingContext {
    var codingUserInfo: [CodingUserInfoKey: Any]? {
        [
            .clientSettings: [
                "client_id": clientId,
                "scope": scope
            ]
        ]
    }
}
