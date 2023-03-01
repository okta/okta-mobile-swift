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

extension DirectAuthenticationFlow.PrimaryFactor: AuthenticationFactor {
    var loginHintKey: String {
        switch self {
        case .password(_):
            return "username"
        default:
            return "login_hint"
        }
    }
    
    func stepHandler(flow: DirectAuthenticationFlow,
                     openIdConfiguration: AuthFoundation.OpenIdConfiguration,
                     loginHint: String,
                     factor: DirectAuthenticationFlow.PrimaryFactor) throws -> StepHandler
    {
        let clientId = flow.client.configuration.clientId
        let scope = flow.client.configuration.scopes

        switch self {
        case .otp(code: _): fallthrough
        case .password(_):
            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientId: clientId,
                                       scope: scope,
                                       loginHint: loginHint,
                                       factor: factor,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenExchangeStepHandler(flow: flow, request: request)
        case .oob(channel: let channel):
            let request = try OOBAuthenticateRequest(openIdConfiguration: openIdConfiguration,
                                                     clientId: clientId,
                                                     loginHint: loginHint,
                                                     channelHint: channel)
            return OOBStepHandler(flow: flow,
                                  openIdConfiguration: openIdConfiguration,
                                  request: request,
                                  factor: factor)
        }
    }
    
    var tokenParameters: [String : Any]? {
        switch self {
        case .otp(code: let code):
            return [
                "grant_type": grantType.rawValue,
                "otp": code
            ]
        case .password(let password):
            return [
                "grant_type": grantType.rawValue,
                "password": password
            ]
        case .oob(channel: _):
            return nil
        }

    }

    var grantType: GrantType {
        switch self {
        case .otp(code: _):
            return .otp
        case .password(_):
            return .password
        case .oob(channel: _):
            return .oob
        }
    }
}
