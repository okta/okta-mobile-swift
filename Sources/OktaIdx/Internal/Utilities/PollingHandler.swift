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

protocol PollingHandlerDelegate: AnyObject {
    func pollingRefreshTime(handler: PollingHandler) -> TimeInterval
    func pollingRemediation(handler: PollingHandler) -> IDXClient.Remediation?
}

class PollingHandler {
    weak var delegate: PollingHandlerDelegate?

    private(set) var isPolling: Bool = false
    
    deinit {
        isPolling = false
    }
    
    func start(completion: @escaping (IDXClient.Response?, Error?) -> Bool) {
        guard !isPolling else { return }
        
        isPolling = true
        nextPoll(completion: completion)
    }
    
    func stopPolling() {
        isPolling = false
    }
    
    func nextPoll(completion: @escaping (IDXClient.Response?, Error?) -> Bool) {
        guard let refreshTime = delegate?.pollingRefreshTime(handler: self),
              refreshTime > 0
        else {
            if !completion(nil, IDXClientError.internalError(message: "Missing polling information")) {
                stopPolling()
            }
            return
        }
        
        let deadlineTime = DispatchTime.now() + refreshTime
        DispatchQueue.global().asyncAfter(deadline: deadlineTime) { [weak self] in
            guard let self = self,
                  let remediation = self.delegate?.pollingRemediation(handler: self)
            else {
                return
            }
            
            if self.isPolling == false {
                return
            }
            
            remediation.proceed { [weak self] (response, error) in
                guard let self = self else { return }
                
                if self.isPolling == false {
                    return
                }
                
                if completion(response, error) {
                    self.nextPoll(completion: completion)
                } else {
                    self.isPolling = false
                }
            }
        }
    }
}
