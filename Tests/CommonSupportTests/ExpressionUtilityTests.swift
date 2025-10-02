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

import XCTest

#if !COCOAPODS
@testable import CommonSupport
#endif

@testable import TestCommon

fileprivate enum ExpressionUtilityError: Error {
    case genericError
    case newError
}

final class ExpressionUtilityTests: XCTestCase {
    func testWithExpressionNoThrow() async throws {
        nonisolated(unsafe) var successCalled = false
        nonisolated(unsafe) var failureCalled: Bool?
        nonisolated(unsafe) var finallyCalled = false

        let result = await withExpression {
            "Hello, World!"
        } success: { value in
            XCTAssertEqual(value, "Hello, World!")
            successCalled = true
        } failure: { error in
            XCTAssertNil(error)
            failureCalled = false
        } finally: {
            finallyCalled = true
        }

        XCTAssertEqual(result, "Hello, World!")
        XCTAssertTrue(successCalled)
        XCTAssertNil(failureCalled)
        XCTAssertTrue(finallyCalled)
    }

    func testWithFailingExpression() async throws {
        nonisolated(unsafe) var successCalled: Bool?
        nonisolated(unsafe) var failureCalled = false
        nonisolated(unsafe) var finallyCalled = false

        let error = await XCTAssertThrowsErrorAsync(try await withExpression {
            throw ExpressionUtilityError.genericError
        } success: { value in
            successCalled = true
        } failure: { error in
            XCTAssertEqual(error as? ExpressionUtilityError, .genericError)
            failureCalled = true
        } finally: {
            finallyCalled = true
        })

        XCTAssertEqual(error as? ExpressionUtilityError, .genericError)
        XCTAssertNil(successCalled)
        XCTAssertTrue(failureCalled)
        XCTAssertTrue(finallyCalled)
    }

    func testWithRethrowingExpression() async throws {
        nonisolated(unsafe) var successCalled: Bool?
        nonisolated(unsafe) var failureCalled = false
        nonisolated(unsafe) var finallyCalled = false

        let error = await XCTAssertThrowsErrorAsync(try await withExpression {
            throw ExpressionUtilityError.genericError
        } success: { value in
            successCalled = true
        } failure: { error in
            XCTAssertEqual(error as? ExpressionUtilityError, .genericError)
            failureCalled = true
            throw ExpressionUtilityError.newError
        } finally: {
            finallyCalled = true
        })

        XCTAssertEqual(error as? ExpressionUtilityError, .newError)
        XCTAssertNil(successCalled)
        XCTAssertTrue(failureCalled)
        XCTAssertTrue(finallyCalled)
    }
}
