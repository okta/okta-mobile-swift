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

extension DirectAuthenticationFlow {
    func process(_ error: APIClientError,
                 completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void)
    {
        guard case let .serverError(serverError) = error,
           let oauthError = serverError as? OAuth2ServerError
        else {
            send(error: DirectAuthenticationFlowError(error), completion: completion)
            return
        }
        
        do {
            send(state: try process(oauthError), completion: completion)
        } catch {
            send(error: DirectAuthenticationFlowError(error), completion: completion)
        }
    }
    
    func process(_ error: OAuth2ServerError) throws -> Status {
        switch error.code {
        case .mfaRequired:
            guard let mfaToken = error.additionalValues["mfaToken"] as? String else {
                throw OAuth2Error.missingOAuth2ResponseKey("mfa_token")
            }

            let supportedTypes = error.additionalValues["supportedChallengeTypes"] as? String

            return .mfaRequired(.init(supportedChallengeTypes: try .from(string: supportedTypes),
                                      mfaToken: mfaToken))
            
        default:
            throw error
        }
    }
}
