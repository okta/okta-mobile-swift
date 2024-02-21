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

class OOBStepHandler<Factor: AuthenticationFactor>: StepHandler {
    let flow: DirectAuthenticationFlow
    let openIdConfiguration: OpenIdConfiguration
    let currentStatus: DirectAuthenticationFlow.Status?
    let loginHint: String?
    let channel: DirectAuthenticationFlow.OOBChannel
    let factor: Factor
    private let bindingContext: DirectAuthenticationFlow.BindingUpdateContext?
    private var poll: PollingHandler<TokenRequest>?
    
    init(flow: DirectAuthenticationFlow,
         openIdConfiguration: OpenIdConfiguration,
         currentStatus: DirectAuthenticationFlow.Status?,
         loginHint: String?,
         channel: DirectAuthenticationFlow.OOBChannel,
         factor: Factor,
         bindingContext: DirectAuthenticationFlow.BindingUpdateContext? = nil) throws
    {
        self.flow = flow
        self.openIdConfiguration = openIdConfiguration
        self.currentStatus = currentStatus
        self.loginHint = loginHint
        self.channel = channel
        self.factor = factor
        self.bindingContext = bindingContext
    }
    
    func process(completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void) {
        if let bindingContext {
            self.requestToken(using: bindingContext.oobResponse, completion: completion)
        } else {
            requestOOBCode { [weak self] result in
                guard let self else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.flow.process(error, completion: completion)
                case .success(let response):
                    switch response.bindingMethod {
                    case .none:
                        self.requestToken(using: response, completion: completion)
                    case .transfer:
                        guard let bindingCode = response.bindingCode,
                              bindingCode.isEmpty == false
                        else {
                            completion(.failure(.bindingCodeMissing))
                            return
                        }
                        
                        completion(.success(.bindingUpdate(.init(update: .transfer(bindingCode),
                                                                 oobResponse: response))))
                    }
                }
            }
        }
    }
    
    // OOB authentication requests differ whether it's used as a primary factor, or a secondary factor.
    // To simplify the code below, we separate this request logic into separate functions to work
    // around differences in the response data.
    private func requestOOBCode(completion: @escaping (Result<OOBResponse, APIClientError>) -> Void) {
        // Request where OOB is used as the primary factor
        if let loginHint = loginHint {
            requestOOBCode(loginHint: loginHint, completion: completion)
        }
        
        // Request where OOB is used as the secondary factor
        else if case let .mfaRequired(context) = currentStatus {
            requestOOBCode(mfaToken: context.mfaToken, completion: completion)
        }
        
        // Cannot create a request
        else {
            completion(.failure(.validation(error: DirectAuthenticationFlowError.missingArguments(["login_hint", "mfa_token"]))))
        }
    }
    
    private func requestOOBCode(loginHint: String,
                                completion: @escaping (Result<OOBResponse, APIClientError>) -> Void)
    {
        do {
            let request = try OOBAuthenticateRequest(openIdConfiguration: openIdConfiguration,
                                                     clientConfiguration: flow.client.configuration,
                                                     loginHint: loginHint,
                                                     channelHint: channel)
            request.send(to: flow.client) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    completion(.success(response.result))
                }
            }
        } catch {
            completion(.failure(.validation(error: error)))
        }
    }
    
    private func requestOOBCode(mfaToken: String,
                                completion: @escaping (Result<OOBResponse, APIClientError>) -> Void)
    {
        do {
            let grantType = factor.grantType(currentStatus: currentStatus)
            let request = try ChallengeRequest(openIdConfiguration: openIdConfiguration,
                                               clientConfiguration: flow.client.configuration,
                                               mfaToken: mfaToken,
                                               challengeTypesSupported: [grantType])
            request.send(to: flow.client) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let response):
                    if let oobResponse = response.result.oobResponse {
                        completion(.success(oobResponse))
                    } else {
                        completion(.failure(.invalidResponse))
                    }
                }
            }
        } catch {
            completion(.failure(.validation(error: error)))
        }
    }

    private func requestToken(using response: OOBResponse, completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void) {
        let request = TokenRequest(openIdConfiguration: openIdConfiguration,
                                   clientConfiguration: flow.client.configuration,
                                   currentStatus: currentStatus,
                                   factor: factor,
                                   parameters: response,
                                   grantTypesSupported: flow.supportedGrantTypes)
        self.poll = PollingHandler(client: flow.client,
                                   request: request,
                                   expiresIn: response.expiresIn,
                                   interval: response.interval) { pollHandler, result in
            switch result {
            case .success(let response):
                return .success(response.result)
            case .failure(let error):
                guard case let .serverError(serverError) = error,
                   let oauthError = serverError as? OAuth2ServerError
                else {
                    return .failure(error)
                }

                switch oauthError.code {
                case .slowDown:
                    pollHandler.interval += 5
                    fallthrough
                case .authorizationPending: fallthrough
                case .directAuthAuthorizationPending:
                    return .continuePolling
                default:
                    return .failure(error)
                }
            }
        }
        
        self.poll?.start { result in
            switch result {
            case .success(let token):
                completion(.success(.success(token)))
            case .failure(let error):
                switch error {
                case .apiClientError(let apiClientError):
                    self.flow.process(apiClientError, completion: completion)
                case .timeout:
                    completion(.failure(.pollingTimeoutExceeded))
                }
            }
            self.poll = nil
        }
    }
}
