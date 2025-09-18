//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@testable import CommonSupport
import XCTest

fileprivate struct TestValue: Sendable, Equatable {
    var firstName: String
    var lastName: String
}

final class CopyOnWriteTests: XCTestCase {
    func testCopiedObjects() async throws {
        var value1 = CopyOnWrite<TestValue>(.init(firstName: "Jane", lastName: "Doe"))
        XCTAssertEqual(value1.value.firstName, "Jane")
        
        var value2 = value1
        XCTAssertEqual(value2.value.firstName, "Jane")
        XCTAssertTrue(value1 === value2)
        XCTAssertEqual(value1.value, value2.value)
        
        value1.value.firstName = "John"
        XCTAssertEqual(value1.value.firstName, "John")
        XCTAssertFalse(value1 === value2)
        XCTAssertNotEqual(value1.value, value2.value)
        
        value1.value.firstName = "Jane"
        XCTAssertEqual(value2.value.firstName, "Jane")
        XCTAssertFalse(value1 === value2)
        
        let value3 = value2
        _ = await Task.detached { @Sendable [value2] in
            var value4 = value2
            XCTAssertTrue(value2 === value3)
            XCTAssertTrue(value2 === value4)

            value4.value.lastName = "Smith"
            XCTAssertEqual(value4.value.lastName, "Smith")
            XCTAssertTrue(value2 === value3)
            XCTAssertFalse(value2 === value4)
        }.result

        XCTAssertTrue(value2 === value3)
        value2.modify { value in
            value.lastName = "Beuller"
        }
        XCTAssertEqual(value2.value.lastName, "Beuller")
        XCTAssertFalse(value2 === value3)
    }
}
