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
import Testing

@testable import AuthFoundation
@testable import TestCommon

fileprivate enum ExpressionUtilityError: Error {
    case genericError
    case newError
}

@Suite("Expression utility helper tests", .disabled("Debugging test deadlocks within CI"))
struct ExpressionUtilityTests {
    @Test("With expression, not throwing an error")
    func testWithExpressionNoThrow() async throws {
        nonisolated(unsafe) var successCalled = false
        nonisolated(unsafe) var failureCalled: Bool?
        nonisolated(unsafe) var finallyCalled = false

        let result = await withExpression {
            "Hello, World!"
        } success: { value in
            #expect(value == "Hello, World!")
            successCalled = true
        } failure: { error in
            // This closure should not be called in the success case
            failureCalled = false
        } finally: {
            finallyCalled = true
        }

        #expect(result == "Hello, World!")
        #expect(successCalled == true)
        #expect(failureCalled == nil)
        #expect(finallyCalled == true)
    }

    @Test("With failing expression")
    func testWithFailingExpression() async throws {
        nonisolated(unsafe) var successCalled: Bool?
        nonisolated(unsafe) var failureCalled = false
        nonisolated(unsafe) var finallyCalled = false

        let error = await #expect(throws: ExpressionUtilityError.self) {
            try await withExpression {
                throw ExpressionUtilityError.genericError
            } success: { value in
                successCalled = true
            } failure: { error in
                #expect(error as? ExpressionUtilityError == .genericError)
                failureCalled = true
            } finally: {
                finallyCalled = true
            }
        }

        #expect(error == .genericError)
        #expect(successCalled == nil)
        #expect(failureCalled == true)
        #expect(finallyCalled == true)
    }

    @Test("With rethrowing expression")
    func testWithRethrowingExpression() async throws {
        nonisolated(unsafe) var successCalled: Bool?
        nonisolated(unsafe) var failureCalled = false
        nonisolated(unsafe) var finallyCalled = false

        let error = await #expect(throws: ExpressionUtilityError.self) {
            try await withExpression {
                throw ExpressionUtilityError.genericError
            } success: { value in
                successCalled = true
            } failure: { error in
                #expect(error as? ExpressionUtilityError == .genericError)
                failureCalled = true
                throw ExpressionUtilityError.newError
            } finally: {
                finallyCalled = true
            }
        }

        #expect(error == .newError)
        #expect(successCalled == nil)
        #expect(failureCalled == true)
        #expect(finallyCalled == true)
    }
}
