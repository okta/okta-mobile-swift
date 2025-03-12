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
import AuthFoundation

extension AuthorizationCodeFlow {
    struct TokenRequest: OAuth2TokenRequest, AuthenticationFlowRequest {
        typealias ResponseType = Token
        typealias Flow = AuthorizationCodeFlow

        let openIdConfiguration: OpenIdConfiguration
        let clientConfiguration: OAuth2Client.Configuration
        let additionalParameters: [String: any APIRequestArgument]?
        let context: Flow.Context
        let redirectUri: URL
        let authorizationCode: String
        
        init(openIdConfiguration: OpenIdConfiguration,
             clientConfiguration: OAuth2Client.Configuration,
             additionalParameters: [String: any APIRequestArgument]?,
             context: Context,
             authorizationCode: String) throws
        {
            guard let redirectUri = clientConfiguration.redirectUri else {
                throw OAuth2Error.missingRedirectUri
            }
            
            self.openIdConfiguration = openIdConfiguration
            self.clientConfiguration = clientConfiguration
            self.additionalParameters = additionalParameters
            self.context = context
            self.authorizationCode = authorizationCode
            self.redirectUri = redirectUri
        }
    }
}

extension AuthorizationCodeFlow.TokenRequest {
    var category: AuthFoundation.OAuth2APIRequestCategory { .token }
    var tokenValidatorContext: any IDTokenValidatorContext { context }
    var bodyParameters: [String: any APIRequestArgument]? {
        var result = additionalParameters ?? [:]
        result.merge(clientConfiguration.parameters(for: category))
        result.merge(context.parameters(for: category))
        result.merge([
            "grant_type": GrantType.authorizationCode,
            GrantType.authorizationCode.responseKey: authorizationCode,
        ])

        return result
    }
}

extension AuthorizationCodeFlow.TokenRequest: APIParsingContext {}
