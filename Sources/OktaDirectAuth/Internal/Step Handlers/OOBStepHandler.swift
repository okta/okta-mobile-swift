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
import CommonSupport

final class OOBStepHandler<Factor: AuthenticationFactor>: StepHandler {
    let flow: DirectAuthenticationFlow
    let openIdConfiguration: OpenIdConfiguration
    let context: DirectAuthenticationFlow.Context
    let loginHint: String?
    let channel: DirectAuthenticationFlow.OOBChannel
    let factor: Factor

    private let lock = Lock()
    nonisolated(unsafe) private var _taskHandle: Task<DirectAuthenticationFlow.Status, any Error>?

    init(flow: DirectAuthenticationFlow,
         openIdConfiguration: OpenIdConfiguration,
         context: DirectAuthenticationFlow.Context,
         loginHint: String?,
         channel: DirectAuthenticationFlow.OOBChannel,
         factor: Factor) throws
    {
        self.flow = flow
        self.openIdConfiguration = openIdConfiguration
        self.context = context
        self.loginHint = loginHint
        self.channel = channel
        self.factor = factor
    }
    
    func process() async throws -> DirectAuthenticationFlow.Status {
        if let bindingContext = context.currentStatus?.continuationType?.bindingContext {
            return try await requestToken(using: bindingContext.oobResponse)
        }
        
        let response = try await requestOOBCode()
        let mfaContext = context.currentStatus?.mfaContext
        
        switch response.bindingMethod {
        case .none:
            return try await requestToken(using: response)
        case .prompt:
            return  .continuation(.prompt(.init(oobResponse: response,
                                                mfaContext: mfaContext)))
        case .transfer:
            guard let bindingCode = response.bindingCode,
                  !bindingCode.isEmpty
            else {
                throw DirectAuthenticationFlowError.bindingCodeMissing
            }
            
            return .continuation(.transfer(.init(oobResponse: response,
                                                 mfaContext: mfaContext),
                                           code: bindingCode))
        }
    }
    
    // OOB authentication requests differ whether it's used as a primary factor, or a secondary factor.
    // To simplify the code below, we separate this request logic into separate functions to work
    // around differences in the response data.
    private func requestOOBCode() async throws -> OOBResponse {
        // Request where OOB is used as the primary factor
        if let loginHint = loginHint {
            return try await requestOOBCode(loginHint: loginHint)
        }
        
        // Request where OOB is used as the secondary factor
        else if case let .mfaRequired(context) = context.currentStatus {
            return try await requestOOBCode(mfaToken: context.mfaToken)
        }
        
        // Cannot create a request
        else {
            throw DirectAuthenticationFlowError.missingArguments(["login_hint", "mfa_token"])
        }
    }
    
    private func requestOOBCode(loginHint: String) async throws -> OOBResponse {
        let request = try OOBAuthenticateRequest(openIdConfiguration: openIdConfiguration,
                                                 clientConfiguration: flow.client.configuration,
                                                 context: context,
                                                 loginHint: loginHint,
                                                 channelHint: channel,
                                                 challengeHint: factor.grantType(currentStatus: context.currentStatus))
        let response = try await request.send(to: flow.client)
        return response.result
    }
    
    private func requestOOBCode(mfaToken: String) async throws -> OOBResponse {
        let grantType = factor.grantType(currentStatus: context.currentStatus)
        let request = try ChallengeRequest(openIdConfiguration: openIdConfiguration,
                                           clientConfiguration: flow.client.configuration,
                                           context: context,
                                           mfaToken: mfaToken,
                                           challengeTypesSupported: [grantType])
        let response = try await request.send(to: flow.client)
        guard let oobResponse = response.result.oobResponse else {
            throw APIClientError.invalidResponse
        }
        
        return oobResponse
    }

    private func requestToken(using response: OOBResponse) async throws -> DirectAuthenticationFlow.Status {
        guard let interval = response.interval else {
            throw DirectAuthenticationFlowError.missingArguments(["interval"])
        }
        
        let client = flow.client
        let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                   clientConfiguration: client.configuration,
                                   context: context,
                                   factor: factor,
                                   parameters: response,
                                   grantTypesSupported: flow.supportedGrantTypes)

        let taskHandle = Task {
            let poll = try APIRequestPollingHandler<TokenRequest, DirectAuthenticationFlow.Status>(
                interval: interval,
                expiresIn: response.expiresIn) { _, request in
                    let response = try await client.exchange(token: request)
                    return .success(.success(response.result))
            }
            return try await poll.start(with: request)
        }

        lock.withLock {
            _taskHandle = taskHandle
        }

        return try await taskHandle.value
    }
}

// Work around a bug in Swift 5.10 that ignores `nonisolated(unsafe)` on mutable stored properties.
#if swift(<6.0)
extension OOBStepHandler: @unchecked Sendable {}
#else
extension OOBStepHandler: Sendable {}
#endif
