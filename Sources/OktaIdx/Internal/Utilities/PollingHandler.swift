//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class PollingHandler {
    private(set) var isPolling: Bool = false
    internal private(set) var pollOption: Remediation

    init(pollOption: Remediation) {
        self.pollOption = pollOption
    }
    
    deinit {
        isPolling = false
    }
    
    func start(completion: @escaping (Result<Response, IDXAuthenticationFlowError>) -> Remediation?) {
        guard !isPolling else { return }
        
        isPolling = true
        nextPoll(completion: completion)
    }
    
    func stopPolling() {
        isPolling = false
    }
    
    func nextPoll(completion: @escaping (Result<Response, IDXAuthenticationFlowError>) -> Remediation?) {
        guard let refreshTime = pollOption.refresh,
              refreshTime > 0
        else {
            let _ = completion(.failure(.internalMessage("Missing polling information")))
            stopPolling()
            return
        }
        
        let deadlineTime = DispatchTime.now() + refreshTime
        DispatchQueue.global().asyncAfter(deadline: deadlineTime) { [weak self] in
            guard let self = self else {
                return
            }
            
            if self.isPolling == false {
                return
            }
            
            self.pollOption.proceed { [weak self] result in
                guard let self = self else { return }
                
                if self.isPolling == false {
                    return
                }
                
                if let nextPollingOption = completion(result) {
                    self.pollOption = nextPollingOption
                    self.nextPoll(completion: completion)
                } else {
                    self.isPolling = false
                }
            }
        }
    }
}
