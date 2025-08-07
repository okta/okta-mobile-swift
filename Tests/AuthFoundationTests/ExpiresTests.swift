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

import Foundation
import Testing

@testable import AuthFoundation

class MockExpires: Expires {
    var expiresIn: TimeInterval = 60
    var issuedAt: Date?
}

@Suite("Expires protocol tests", .disabled("Debugging test deadlocks within CI"))
struct ExpiresTests {
    let expires = MockExpires()
    
    @Test("Null issue date")
    func testNullIssueDate() {
        #expect(expires.expiresAt == nil)
        #expect(!expires.isExpired)
        #expect(expires.isValid)
    }
    
    @Test("Valid time")
    func testValidTime() {
        expires.issuedAt = Date()
        #expect(expires.isValid)
        #expect(!expires.isExpired)
    }

    @Test("Expired time")
    func testExpiredTime() {
        expires.issuedAt = Date(timeIntervalSinceNow: -300)
        #expect(!expires.isValid)
        #expect(expires.isExpired)
    }
}
