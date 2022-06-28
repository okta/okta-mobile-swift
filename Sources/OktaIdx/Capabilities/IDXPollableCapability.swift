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

extension Capability {
    /// Capability for authentiators or remedations to be polled to determine out-of-band actions taken by the user.
    public class Pollable: AuthenticatorCapability, RemediationCapability {
        /// Indicates whether or not this authenticator is actively polling.
        public var isPolling: Bool { pollHandler?.isPolling ?? false }
        
        /// Starts the polling process.
        ///
        /// The action will be continually polled in the background either until ``stopPolling`` is called, or when the authenticator has finished. The completion block is invoked once the user has completed the action out-of-band, or when an error is received.
        /// - Parameter completion: Completion handler when the polling is complete, or `nil` if the developer does not need to handle the response
        public func startPolling(completion: InteractionCodeFlow.ResponseResult? = nil) {
            // Stop any previous polling
            stopPolling()
            
            let authenticatorType = self.authenticatorType
            let handler = PollingHandler(pollOption: remediation)
            handler.start { result in
                switch result {
                case .failure(let error):
                    completion?(.failure(error))
                    return nil
                    
                case .success(let response):
                    // If we don't get another email authenticator back, we know the
                    // magic link was clicked, and we can proceed to the completion block.
                    guard let currentAuthenticator = response.authenticators.current,
                          let nextPoll = currentAuthenticator.capability(Capability.Pollable.self),
                          currentAuthenticator.type == authenticatorType
                    else {
                        completion?(.success(response))
                        return nil
                    }
                    
                    return nextPoll.remediation
                }
            }
            pollHandler = handler
        }
        
        /// Stops the polling process from continuing.
        public func stopPolling() {
            pollHandler?.stopPolling()
            pollHandler = nil
        }
        
        internal private(set) weak var flow: InteractionCodeFlowAPI?
        internal private(set) var remediation: Remediation
        internal let authenticatorType: Authenticator.Kind
        private var pollHandler: PollingHandler?
        internal init(flow: InteractionCodeFlowAPI,
                      authenticatorType: Authenticator.Kind,
                      remediation: Remediation)
        {
            self.flow = flow
            self.authenticatorType = authenticatorType
            self.remediation = remediation
        }
    }
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension Capability.Pollable {
    /// Starts the polling process asynchronously.
    ///
    /// The action will be continually polled in the background either until ``stopPolling`` is called, or when the authenticator has finished.
    /// - Returns: The next response after polling completes successfully
    public func startPolling() async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            startPolling() { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
