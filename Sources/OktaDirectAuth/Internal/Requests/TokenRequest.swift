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
import APIClient

struct TokenRequest: Sendable {
    let openIdConfiguration: OpenIdConfiguration
    let clientConfiguration: OAuth2Client.Configuration
    let currentStatus: DirectAuthenticationFlow.Status?
    let loginHint: String?
    let factor: (any AuthenticationFactor & Sendable)
    let intent: DirectAuthenticationFlow.Intent
    let parameters: (any HasTokenParameters & Sendable)?
    let grantTypesSupported: [GrantType]?
    
    init(openIdConfiguration: OpenIdConfiguration,
         clientConfiguration: OAuth2Client.Configuration,
         currentStatus: DirectAuthenticationFlow.Status?,
         loginHint: String? = nil,
         factor: any AuthenticationFactor,
         intent: DirectAuthenticationFlow.Intent,
         parameters: (any HasTokenParameters)? = nil,
         grantTypesSupported: [GrantType]? = nil)
    {
        self.openIdConfiguration = openIdConfiguration
        self.clientConfiguration = clientConfiguration
        self.currentStatus = currentStatus
        self.loginHint = loginHint
        self.factor = factor
        self.intent = intent
        self.parameters = parameters
        self.grantTypesSupported = grantTypesSupported
    }
}

extension TokenRequest: OAuth2TokenRequest, OAuth2APIRequest, APIRequestBody {
    var clientId: String { clientConfiguration.clientId }
    var bodyParameters: [String: any APIRequestArgument]? {
        var result = factor.tokenParameters(currentStatus: currentStatus)
        result["client_id"] = clientConfiguration.clientId
        result["scope"] = clientConfiguration.scopes
        
        result.merge(parameters?.tokenParameters(currentStatus: currentStatus))
        
        if let loginHint = loginHint {
            let key: String
            if let factor = factor as? DirectAuthenticationFlow.PrimaryFactor {
                key = factor.loginHintKey
            } else {
                key = "login_hint"
            }
            result[key] = loginHint
        }
        
        if let grantTypesSupported = grantTypesSupported?.map(\.rawValue) {
            result["grant_types_supported"] = grantTypesSupported.joined(separator: " ")
        }
        
        result.merge(clientConfiguration.authentication)
        result.merge(intent)

        return result
    }
}

extension TokenRequest: APIParsingContext {
    var codingUserInfo: [CodingUserInfoKey: any Sendable]? {
        [
            .clientSettings: [
                "client_id": clientConfiguration.clientId,
                "scope": clientConfiguration.scopes
            ]
        ]
    }
}
