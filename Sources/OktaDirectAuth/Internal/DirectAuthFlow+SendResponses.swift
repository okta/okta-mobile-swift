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
    func send(success response: APIResponse<Token>,
              completion: @escaping (Result<Status, DirectAuthenticationFlowError>) -> Void)
    {
        reset()
        delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
        completion(.success(.success(response.result)))
    }

    func send(state: Status,
              completion: @escaping (Result<Status, DirectAuthenticationFlowError>) -> Void)
    {
        delegateCollection.invoke { $0.authentication(flow: self, received: state) }
        completion(.success(state))
    }

    func send(error: Error,
              completion: @escaping (Result<Status, DirectAuthenticationFlowError>) -> Void)
    {
        reset()
        
        let oauth2Error = OAuth2Error(error)
        delegateCollection.invoke { $0.authentication(flow: self, received: oauth2Error) }

        completion(.failure(DirectAuthenticationFlowError(error)))
    }
}
