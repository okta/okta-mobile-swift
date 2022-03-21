//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import AuthFoundation

class MockExpires: Expires {
    var expiresIn: TimeInterval = 60
    var issuedAt: Date?
}

final class ExpiresTests: XCTestCase {
    let expires = MockExpires()
    
    override func setUpWithError() throws {
        DefaultTimeCoordinator.resetToDefault()
    }
    
    func testNullIssueDate() {
        XCTAssertNil(expires.expiresAt)
        XCTAssertFalse(expires.isExpired)
        XCTAssertTrue(expires.isValid)
    }
    
    func testValidTime() {
        expires.issuedAt = Date()
        XCTAssertTrue(expires.isValid)
        XCTAssertFalse(expires.isExpired)
    }

    func testExpiredTime() {
        expires.issuedAt = Date(timeIntervalSinceNow: -300)
        XCTAssertFalse(expires.isValid)
        XCTAssertTrue(expires.isExpired)
    }
}
