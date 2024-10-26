//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension DirectAuthenticationFlow.ContinuationFactor: AuthenticationFactor {
    func stepHandler(flow: DirectAuthenticationFlow,
                     openIdConfiguration: OpenIdConfiguration,
                     loginHint: String? = nil,
                     currentStatus: DirectAuthenticationFlow.Status?,
                     factor: Self) throws -> any StepHandler
    {
        let bindingContext = currentStatus?.continuationType?.bindingContext
        
        switch self {
        case .transfer:
            guard let bindingContext = bindingContext
            else {
                throw DirectAuthenticationFlowError.invalidContinuationContext
            }
            
            return try OOBStepHandler(flow: flow,
                                      openIdConfiguration: openIdConfiguration,
                                      currentStatus: currentStatus,
                                      loginHint: loginHint,
                                      channel: bindingContext.oobResponse.channel,
                                      factor: factor)

        case .prompt(code: _):
            guard let bindingContext = bindingContext
            else {
                throw DirectAuthenticationFlowError.invalidContinuationContext
            }

            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientConfiguration: flow.client.configuration,
                                       currentStatus: currentStatus,
                                       factor: factor,
                                       intent: flow.intent,
                                       parameters: bindingContext.oobResponse,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenStepHandler(flow: flow, request: request)

        case .webAuthn(response: let response):
            let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                       clientConfiguration: flow.client.configuration,
                                       currentStatus: currentStatus,
                                       loginHint: loginHint,
                                       factor: factor,
                                       intent: flow.intent,
                                       parameters: response,
                                       grantTypesSupported: flow.supportedGrantTypes)
            return TokenStepHandler(flow: flow, request: request)
        }
    }
    
    func grantType(currentStatus: DirectAuthenticationFlow.Status?) -> GrantType {
        let hasMFAToken = (currentStatus?.mfaContext?.mfaToken != nil)

        switch self {
        case .webAuthn(response: _):
            if hasMFAToken {
                return .webAuthnMFA
            } else {
                return .webAuthn
            }
        case .transfer, .prompt(code: _):
            if hasMFAToken {
                return .oobMFA
            } else {
                return .oob
            }
        }
    }
}

extension DirectAuthenticationFlow.ContinuationFactor: HasTokenParameters {
    func tokenParameters(currentStatus: DirectAuthenticationFlow.Status?) -> [String: any APIRequestArgument] {
        var result: [String: any APIRequestArgument] = [
            "grant_type": grantType(currentStatus: currentStatus),
        ]
        
        if let context = currentStatus?.mfaContext {
            result["mfa_token"] = context.mfaToken
        }
        
        if let context = currentStatus?.continuationType?.bindingContext {
            result["oob_code"] = context.oobResponse.oobCode
        }
        
        if case let .prompt(code) = self {
            result["binding_code"] = code
        }
        
        return result
    }
}
