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

/// Convenience function that wraps an expression so that results, or thrown errors, can be propagated to the appropriate underlying delegate functions as necessary.
/// - Parameters:
///   - expression: Expression to invoke which should be wrapped by the delegate collection
///   - success: Closure invoked when the expression is successful
///   - failure: Closure invoked when the expression throws an error
/// - Returns: The result when the expression is successful
@inlinable
@_documentation(visibility: private)
public func withExpression<T>(_ expression: () async throws -> T,
                              success: (T) -> Void = { _ in },
                              failure: (Error) throws -> Void = { _ in },
                              finally: () -> Void = {}) async rethrows -> T
{
    defer { finally() }
    do {
        let result = try await expression()
        success(result)
        return result
    } catch {
        try failure(error)
        throw error
    }
}
