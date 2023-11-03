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

struct TokenStepHandler: StepHandler {
    let flow: DirectAuthenticationFlow
    let request: any OAuth2TokenRequest
    
    func process(completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void) {
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
