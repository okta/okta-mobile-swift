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

class ChallengeStepHandler<Request: APIRequest>: StepHandler {
    let flow: DirectAuthenticationFlow
    let request: Request
    private let statusBlock: (_ response: Request.ResponseType) throws -> DirectAuthenticationFlow.Status

    init(flow: DirectAuthenticationFlow,
         request: Request,
         statusBlock: @escaping (_ response: Request.ResponseType) throws -> DirectAuthenticationFlow.Status)
    {
        self.flow = flow
        self.request = request
        self.statusBlock = statusBlock
    }
    
    func process(completion: @escaping (Result<DirectAuthenticationFlow.Status, DirectAuthenticationFlowError>) -> Void) {
        request.send(to: flow.client) { result in
            switch result {
            case .failure(let error):
                self.flow.process(error, completion: completion)
            case .success(let response):
                do {
                    let status = try self.statusBlock(response.result)
                    completion(.success(status))
                } catch {
                    completion(.failure(.init(error)))
                }
            }
        }
    }
}
