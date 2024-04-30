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
                     factor: Self) throws -> StepHandler
    {
        switch self {
        case .otp:
            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientConfiguration: flow.client.configuration,
                                       currentStatus: currentStatus,
                                       loginHint: loginHint,
                                       factor: factor,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenStepHandler(flow: flow, request: request)
        case .oob(channel: let channel):
            return try OOBStepHandler(flow: flow,
                                      openIdConfiguration: openIdConfiguration,
                                      currentStatus: currentStatus,
                                      loginHint: loginHint,
                                      channel: channel,
                                      factor: factor)
        case .webAuthn:
            let mfaContext = currentStatus?.mfaContext
            let request = try WebAuthnChallengeRequest(openIdConfiguration: openIdConfiguration,
                                                       clientConfiguration: flow.client.configuration,
                                                       loginHint: loginHint,
                                                       mfaToken: mfaContext?.mfaToken)
            return ChallengeStepHandler(flow: flow, request: request) {
                .continuation(.webAuthn(.init(request: $0, mfaContext: mfaContext)))
            }
        }
    }
    
    func grantType(currentStatus: DirectAuthenticationFlow.Status?) -> GrantType {
        let hasMFAToken = (currentStatus?.mfaContext?.mfaToken != nil)

        switch self {
        case .otp:
            return .otpMFA
        case .oob:
            if hasMFAToken {
                return .oobMFA
            } else {
                return .oob
            }
        case .webAuthn:
            if hasMFAToken {
                return .webAuthnMFA
            } else {
                return .webAuthn
            }
        }
    }
}

extension DirectAuthenticationFlow.SecondaryFactor: HasTokenParameters {
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: String] {
        var result: [String: String] = [
            "grant_type": grantType(currentStatus: currentStatus).rawValue,
        ]
        
        if let context = currentStatus?.mfaContext {
            result["mfa_token"] = context.mfaToken
        }

        if case let .otp(code: code) = self {
            result["otp"] = code
        }

        return result
    }
}
