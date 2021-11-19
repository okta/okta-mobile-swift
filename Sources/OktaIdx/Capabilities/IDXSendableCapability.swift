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
    /// Capability used for being able to "send".
    ///
    /// This is typically used by Email and Phone authenticators.
    public struct Sendable: AuthenticatorCapability {
        /// Sends a new authentication code.
        /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
        public func send(completion: IDXClient.ResponseResult? = nil) {
            guard let client = client else {
                completion?(.failure(.invalidClient))
                return
            }

            client.proceed(remediation: remediation, completion: completion)
        }
        
        internal private(set) weak var client: IDXClientAPI?
        internal let remediation: IDXClient.Remediation
        internal init(client: IDXClientAPI,
                      remediation: IDXClient.Remediation)
        {
            self.client = client
            self.remediation = remediation
        }
    }
}
