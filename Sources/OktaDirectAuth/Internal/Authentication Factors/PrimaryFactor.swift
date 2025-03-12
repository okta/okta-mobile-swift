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

extension DirectAuthenticationFlow.PrimaryFactor {
    var loginHintKey: String {
        switch self {
        case .password:
            return "username"
        default:
            return "login_hint"
        }
    }
}

extension DirectAuthenticationFlow.PrimaryFactor: AuthenticationFactor {
    func stepHandler(flow: DirectAuthenticationFlow,
                     openIdConfiguration: OpenIdConfiguration,
                     loginHint: String? = nil) async throws -> any StepHandler
    {
        guard let context = await flow._context else {
            throw DirectAuthenticationFlowError.inconsistentContextState
        }
        
        switch self {
        case .otp: fallthrough
        case .password:
            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientConfiguration: flow.client.configuration,
                                       context: context,
                                       loginHint: loginHint,
                                       factor: self,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenStepHandler(flow: flow, request: request)
        case .oob(channel: let channel):
            return try OOBStepHandler(flow: flow,
                                      openIdConfiguration: openIdConfiguration,
                                      context: context,
                                      loginHint: loginHint,
                                      channel: channel,
                                      factor: self)
        case .webAuthn:
            let mfaContext = context.currentStatus?.mfaContext
            let request = try WebAuthnChallengeRequest(openIdConfiguration: openIdConfiguration,
                                                       clientConfiguration: flow.client.configuration,
                                                       context: context,
                                                       loginHint: loginHint,
                                                       mfaToken: mfaContext?.mfaToken)
            return ChallengeStepHandler(flow: flow, request: request) {
                .continuation(.webAuthn(.init(request: $0, mfaContext: mfaContext)))
            }
        }
    }
    
    func grantType(currentStatus: DirectAuthenticationFlow.Status?) -> GrantType {
        switch self {
        case .otp:
            return .otp
        case .password:
            return .password
        case .oob:
            return .oob
        case .webAuthn:
            return .webAuthn
        }
    }
}

extension DirectAuthenticationFlow.PrimaryFactor: HasTokenParameters {
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: any APIRequestArgument] {
        var result: [String: any APIRequestArgument] = [
            "grant_type": grantType(currentStatus: currentStatus),
        ]
        
        switch self {
        case .otp(code: let code):
            result["otp"] = code
        case .password(let password):
            result["password"] = password
        case .oob: break
        case .webAuthn: break
        }
        
        return result
    }
}
