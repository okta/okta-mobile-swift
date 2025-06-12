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

/// Capability to recover an account.
public struct RecoverCapability: Capability, Sendable, Equatable, Hashable {
    /// Requests that the recovery code is sent.
    public func recover() async throws -> Response {
        try await remediation.proceed()
    }

    internal let remediation: Remediation
    internal init(remediation: Remediation) {
        self.remediation = remediation
    }
}

extension RecoverCapability {
    /// Requests that the recovery code is sent.
    /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
    public func recover(completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await recover()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
