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
        var bindingContext: DirectAuthenticationFlow.BindingUpdateContext?
        if case .bindingUpdate(let context) = currentStatus {
            bindingContext = context
        }
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
                                      factor: factor,
                                      bindingContext: bindingContext)
        case .webAuthn:
            let mfaContext = currentStatus?.mfaContext
            let request = try WebAuthnChallengeRequest(openIdConfiguration: openIdConfiguration,
                                                       clientConfiguration: flow.client.configuration,
                                                       loginHint: loginHint,
                                                       mfaToken: mfaContext?.mfaToken)
            return ChallengeStepHandler(flow: flow, request: request) {
                .webAuthn(.init(request: $0,
                                mfaContext: mfaContext))
            }
        case .webAuthnAssertion(let response):
            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientConfiguration: flow.client.configuration,
                                       currentStatus: currentStatus,
                                       loginHint: loginHint,
                                       factor: factor,
                                       parameters: response,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenStepHandler(flow: flow, request: request)
        }
    }
    
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: String] {
        var result: [String: String] = [
            "grant_type": grantType(currentStatus: currentStatus).rawValue,
        ]
        
        if let context = currentStatus?.mfaContext {
            result["mfa_token"] = context.mfaToken
        }

        switch self {
        case .otp(code: let code):
            result["otp"] = code
        case .webAuthnAssertion(_): break
        case .oob(channel: _): break
        case .webAuthn: break
        }

        return result
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
        case .webAuthn, .webAuthnAssertion(_):
            if hasMFAToken {
                return .webAuthnMFA
            } else {
                return .webAuthn
            }
        }
    }
}
