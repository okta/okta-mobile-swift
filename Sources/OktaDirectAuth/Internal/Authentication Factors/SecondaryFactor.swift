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

extension DirectAuthenticationFlow.SecondaryFactor: AuthenticationFactor {
    func stepHandler(flow: DirectAuthenticationFlow,
                     openIdConfiguration: AuthFoundation.OpenIdConfiguration,
                     loginHint: String? = nil,
                     currentStatus: DirectAuthenticationFlow.Status?,
                     factor: DirectAuthenticationFlow.SecondaryFactor) throws -> StepHandler
    {
        switch self {
        case .otp:
            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientConfiguration: flow.client.configuration,
                                       loginHint: loginHint,
                                       factor: factor,
                                       mfaToken: currentStatus?.mfaToken,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenStepHandler(flow: flow, request: request)
        case .oob(channel: let channel):
            return try OOBStepHandler(flow: flow,
                                      openIdConfiguration: openIdConfiguration,
                                      loginHint: loginHint,
                                      mfaToken: currentStatus?.mfaToken,
                                      channel: channel,
                                      factor: factor)
        }
    }
    
    var tokenParameters: [String: Any]? {
        switch self {
        case .otp(code: let code):
            return [
                "grant_type": grantType.rawValue,
                "otp": code
            ]
        case .oob:
            return nil
        }

    }

    var grantType: GrantType {
        switch self {
        case .otp:
            return .otpMFA
        case .oob:
            return .oobMFA
        }
    }
}
