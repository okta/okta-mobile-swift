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

/// Capability used for being able to "resend" a verification code.
///
/// This is typically used by Email and Phone authenticators.
public struct ResendCapability: Capability, Sendable, Equatable, Hashable {
    /// Resends a new authentication code.
    public func resend() async throws -> Response {
        try await remediation.proceed()
    }

    internal let remediation: Remediation
    internal init(remediation: Remediation) {
        self.remediation = remediation
    }
}

extension ResendCapability {
    /// Resends a new authentication code.
    /// - Parameter completion: Completion handler when the response is returned with the result of the operation.
    public func resend(completion: @escaping @Sendable (Result<Response, any Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await resend()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
