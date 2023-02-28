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

protocol AuthenticationFactor {
    var isTokenRequest: Bool { get }
    var grantType: GrantType { get }
    var tokenParameters: [String: Any]? { get }
    var loginHintKey: String { get }

    func stepHandler(flow: DirectAuthenticationFlow,
                     openIdConfiguration: OpenIdConfiguration,
                     loginHint: String,
                     factor: DirectAuthenticationFlow.PrimaryFactor) throws -> any StepHandler
}

extension DirectAuthenticationFlow.PrimaryFactor: AuthenticationFactor {
    var loginHintKey: String {
        switch self {
        case .password(_):
            return "username"
        default:
            return "login_hint"
        }
    }
    
    var isTokenRequest: Bool {
        switch self {
        case .otp(code: _): fallthrough
        case .password(_):
            return true
        case .oob(channel: _):
            return false
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
            return TokenExchangeHandler(flow: flow, request: request)
        case .oob(channel: let channel):
            let request = try OOBAuthenticateRequest(openIdConfiguration: openIdConfiguration,
                                                     clientId: clientId,
                                                     loginHint: loginHint,
                                                     channelHint: channel)
            return OOBHandler(flow: flow,
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

protocol StepHandler {
    var flow: DirectAuthenticationFlow { get }
    func process(completion: @escaping (Result<DirectAuthenticationFlow.State, OAuth2Error>) -> Void)
}

struct TokenExchangeHandler: StepHandler {
    let flow: DirectAuthenticationFlow
    let request: any OAuth2TokenRequest
    
    func process(completion: @escaping (Result<DirectAuthenticationFlow.State, OAuth2Error>) -> Void) {
        flow.client.exchange(token: request) { result in
            switch result {
            case .failure(let error):
                flow.process(error, completion: completion)
                
            case .success(let response):
                flow.send(success: response, completion: completion)
            }
        }
    }
}

class OOBHandler: StepHandler {
    let flow: DirectAuthenticationFlow
    let openIdConfiguration: OpenIdConfiguration
    let request: OOBAuthenticateRequest
    let factor: DirectAuthenticationFlow.PrimaryFactor
    private var poll: PollingHandler<TokenRequest>?
    
    init(flow: DirectAuthenticationFlow, openIdConfiguration: OpenIdConfiguration, request: OOBAuthenticateRequest, factor: DirectAuthenticationFlow.PrimaryFactor) {
        self.flow = flow
        self.openIdConfiguration = openIdConfiguration
        self.request = request
        self.factor = factor
    }
    
    func process(completion: @escaping (Result<DirectAuthenticationFlow.State, OAuth2Error>) -> Void) {
        request.send(to: flow.client) { result in
            switch result {
            case .failure(let error):
                self.flow.process(error, completion: completion)
                
            case .success(let response):
                let request = TokenRequest(openIdConfiguration: self.openIdConfiguration,
                                           clientId: self.flow.client.configuration.clientId,
                                           scope: self.flow.client.configuration.scopes,
                                           factor: self.factor,
                                           oobCode: response.result.oobCode,
                                           grantTypesSupported: self.flow.supportedGrantTypes)
                self.poll = PollingHandler(client: self.flow.client,
                                           request: request,
                                           expiresIn: response.result.expiresIn,
                                           interval: response.result.interval) { pollHandler, result in
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
                        case .authorizationPending:
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
                        case .apiClientError(let error):
                            completion(.failure(.error(error)))
                        case .timeout:
                            completion(.failure(.error(error)))
                        }
                    }
                    self.poll = nil
                }
            }
        }
    }
}
