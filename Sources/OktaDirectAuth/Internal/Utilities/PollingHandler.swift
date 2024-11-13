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
import AuthFoundation
import OktaConcurrency
import OktaConcurrency
import APIClient

@HasLock
final class PollingHandler<RequestType: OAuth2TokenRequest>: Sendable {
    @Synchronized
    private(set) var isPolling: Bool
    
    @Synchronized
    var interval: TimeInterval
    
    let expirationDate: Date
    let request: RequestType

    private let client: OAuth2Client
    private let statusCheck: @Sendable (PollingHandler, Result<APIResponse<RequestType.ResponseType>, APIClientError>) -> Status

    enum Status: Sendable {
        case continuePolling
        case success(RequestType.ResponseType)
        case failure(APIClientError)
    }
    
    enum PollingError: Error, Sendable {
        case apiClientError(APIClientError)
        case timeout
    }
    
    init(client: OAuth2Client,
         request: RequestType,
         expiresIn: TimeInterval,
         interval: TimeInterval,
         statusCheck: @Sendable @escaping (PollingHandler, Result<APIResponse<RequestType.ResponseType>, APIClientError>) -> Status)
    {
        self.client = client
        self.request = request
        self.expirationDate = Date(timeIntervalSinceNow: expiresIn)
        self.statusCheck = statusCheck
        _interval = interval
        _isPolling = false
    }
    
    deinit {
        isPolling = false
    }
    
    func start(completion: @Sendable @escaping (Result<RequestType.ResponseType, PollingError>) -> Void) {
        guard !isPolling else { return }
        
        isPolling = true
        nextPoll(completion: completion)
    }
    
    func stopPolling() {
        isPolling = false
    }
    
    func nextPoll(completion: @Sendable @escaping (Result<RequestType.ResponseType, PollingError>) -> Void) {
        guard expirationDate.timeIntervalSinceNow >= 0 else {
            completion(.failure(.timeout))
            return
        }
        
        let deadlineTime = DispatchTime.now() + interval
        DispatchQueue.global().asyncAfter(deadline: deadlineTime) { [weak self] in
            guard let self = self else {
                return
            }
            
            if self.isPolling == false {
                return
            }
            
            self.client.exchange(token: self.request) { [weak self] result in
                guard let self = self else { return }
                
                if self.isPolling == false {
                    return
                }
                
                switch self.statusCheck(self, result) {
                case .continuePolling:
                    self.nextPoll(completion: completion)
                case .failure(let error):
                    completion(.failure(.apiClientError(error)))
                    self.isPolling = false
                case .success(let result):
                    completion(.success(result))
                    self.isPolling = false
                }
            }
        }
    }
}
