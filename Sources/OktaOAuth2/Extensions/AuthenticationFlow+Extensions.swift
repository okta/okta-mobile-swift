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

//extension UsesDelegateCollection {
//    /// Convenience function that wraps an expression so that results, or thrown errors, can be propagated to the appropriate underlying delegate functions as necessary.
//    /// - Parameters:
//    ///   - expression: Expression to invoke which should be wrapped by the delegate collection
//    ///   - success: Closure invoked when the expression is successful
//    ///   - failure: Closure invoked when the expression throws an error
//    /// - Returns: The result when the expression is successful
//    @inlinable
//    public func withDelegateCollection<T>(_ expression: () async throws -> T, success: (T) -> Void, failure: (Error) -> Void) async throws -> T {
//        do {
//            let result = try await expression()
//            success(result)
//            return result
//        } catch {
//            failure(error)
//            throw error
//        }
//    }
//}
//
//extension AuthenticationFlow {
//    @_documentation(visibility: private)
//    @inlinable
//    public func returnToken(_ expression: () async throws -> Token) async throws -> Token {
//        try await withDelegateCollection(expression) { (token) in
//            delegateCollection.invoke { $0.authentication(flow: self, received: token) }
//        } failure: { ( error) in
//            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
//        }
//    }
//}
