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

struct TokenRequest: AuthenticationFlowRequest {
    typealias Flow = DirectAuthenticationFlow
    
    let openIdConfiguration: OpenIdConfiguration
    let clientConfiguration: OAuth2Client.Configuration
    let context: Flow.Context
    let loginHint: String?
    let factor: any AuthenticationFactor
    let parameters: (any HasTokenParameters)?
    let grantTypesSupported: [GrantType]?

    init(openIdConfiguration: OpenIdConfiguration,
         clientConfiguration: OAuth2Client.Configuration,
         context: DirectAuthenticationFlow.Context,
         loginHint: String? = nil,
         factor: any AuthenticationFactor,
         parameters: (any HasTokenParameters)? = nil,
         grantTypesSupported: [GrantType]? = nil)
    {
        self.openIdConfiguration = openIdConfiguration
        self.clientConfiguration = clientConfiguration
        self.context = context
        self.loginHint = loginHint
        self.factor = factor
        self.parameters = parameters
        self.grantTypesSupported = grantTypesSupported
    }
}

extension TokenRequest: OAuth2TokenRequest, OAuth2APIRequest, APIRequestBody {
    var category: OAuth2APIRequestCategory { .token }
    var tokenValidatorContext: any IDTokenValidatorContext { NullIDTokenValidatorContext }
    var bodyParameters: [String: APIRequestArgument]? {
        var result = clientConfiguration.parameters(for: category) ?? [:]
        result.merge(context.parameters(for: category))
        result.merge(factor.tokenParameters(currentStatus: context.currentStatus))
        result.merge(parameters?.tokenParameters(currentStatus: context.currentStatus))

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
        
        if result["client_id"] == nil {
            result["client_id"] = clientConfiguration.clientId
        }

        return result
    }
}
