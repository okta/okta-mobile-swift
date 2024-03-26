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
@testable import AuthFoundation
import TestCommon

struct TestClaims: HasClaims {
    enum TestClaim: String, IsClaim {
        case firstName, lastName, modifiedDate, webpage, roles
    }
    
    enum Role: String, ClaimConvertable, IsClaim {
        case admin, superuser, user, guest
    }

    typealias ClaimType = TestClaim
    let payload: [String: Any]
}

extension Date {
    static func nowTruncated() throws -> Date {
        var dateComponents = Calendar.current.dateComponents(in: try XCTUnwrap(TimeZone(identifier: "UTC")), from: Date())
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        return try XCTUnwrap(dateComponents.date)
    }
}

final class ClaimTests: XCTestCase {
    func testClaimConvertible() throws {
        let date = try Date.nowTruncated()
        let dateString = ISO8601DateFormatter().string(from: date)
        let container = TestClaims(payload: [
            "firstName": "Jane",
            "lastName": "Doe",
            "modifiedDate": dateString,
            "webpage": "https://example.com/jane.doe/",
            "roles": ["admin", "user"]
        ])
        let webpage = try XCTUnwrap(URL(string: "https://example.com/jane.doe/"))
        
        XCTAssertEqual(container["firstName"], "Jane")
        XCTAssertEqual(container[.firstName], "Jane")

        XCTAssertEqual(container["lastName"], "Doe")
        XCTAssertEqual(container[.lastName], "Doe")

        XCTAssertEqual(container["modifiedDate"], dateString)
        XCTAssertEqual(container[.modifiedDate], dateString)
        XCTAssertEqual(container.value(Date.self, for: "modifiedDate"), date)

        XCTAssertEqual(container["roles"], ["admin", "user"])
        XCTAssertEqual(container[.roles], ["admin", "user"])
        XCTAssertEqual(container.value([String].self, for: "roles"), ["admin", "user"])
        XCTAssertEqual(container.arrayValue(String.self, for: "roles"), ["admin", "user"])
        XCTAssertEqual(container.arrayValue(TestClaims.Role.self, for: "roles"), [.admin, .user])
        
        XCTAssertEqual(container["webpage"], "https://example.com/jane.doe/")
        XCTAssertEqual(container[.webpage], "https://example.com/jane.doe/")
        XCTAssertEqual(container.value(URL.self, for: "webpage"), webpage)

        var url: URL?
        url = container["webpage"]
        XCTAssertEqual(url, webpage)

        url = container[.webpage]
        XCTAssertEqual(url, webpage)
    }
}
