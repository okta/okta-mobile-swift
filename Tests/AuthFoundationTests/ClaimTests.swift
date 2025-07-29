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
import TestCommon

struct TestClaims: HasClaims {
    enum TestClaim: String, IsClaim {
        case firstName, lastName, modifiedDate, webpage, roles, tags
    }
    
    enum Role: String, ClaimConvertable, IsClaim {
        case admin, superuser, user, guest
    }

    typealias ClaimType = TestClaim
    let payload: [String: any Sendable]
}

extension Date {
    static func nowTruncated() throws -> Date {
        var dateComponents = Calendar.current.dateComponents(in: try #require(TimeZone(identifier: "UTC")), from: Date())
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        return try #require(dateComponents.date)
    }
}

@Suite("Claim System and Type Conversion")
struct ClaimTests {
    @Test("Claim container type conversion and access patterns")
    func testClaimConvertible() throws {
        let date = try Date.nowTruncated()
        let dateString = ISO8601DateFormatter().string(from: date)
        let container = TestClaims(payload: [
            "firstName": "Jane",
            "lastName": "Doe",
            "modifiedDate": dateString,
            "webpage": "https://example.com/jane.doe/",
            "roles": ["admin", "user"],
            "scope": "openid profile offline_access",
            "tags": [
                "popular": "Popular Items",
                "normal": "Normal Items",
            ]
        ])
        let webpage = try #require(URL(string: "https://example.com/jane.doe/"))
        
        #expect(container["firstName"] == "Jane")
        #expect(container[.firstName] == "Jane")

        #expect(container["lastName"] == "Doe")
        #expect(container[.lastName] == "Doe")

        #expect(container["modifiedDate"] == dateString)
        #expect(container[.modifiedDate] == dateString)
        #expect(try container.value(for: "modifiedDate") == date)

        #expect(container["scope"] == "openid profile offline_access")
        #expect(container["scope"] == ["openid", "profile", "offline_access"])
        let scopeOptionalArray: [String]? = container.value(for: "scope")
        #expect(scopeOptionalArray == ["openid", "profile", "offline_access"])
        let scopeArray: [String] = try container.value(for: "scope")
        #expect(scopeArray == ["openid", "profile", "offline_access"])

        #expect(container["roles"] == ["admin", "user"])
        #expect(container[.roles] == ["admin", "user"])
        #expect(container[.roles] == [TestClaims.Role.admin, TestClaims.Role.user])
        #expect(try container.value(for: "roles") == ["admin", "user"])
        #expect(try container.value(for: "roles") as [TestClaims.Role] == [.admin, .user])
        
        #expect(try container.value(for: "tags") == [
            "popular": "Popular Items",
            "normal": "Normal Items",
        ])
        #expect(try container.value(for: .tags) == [
            "popular": "Popular Items",
            "normal": "Normal Items",
        ])
        #expect(container["tags"] == [
            "popular": "Popular Items",
            "normal": "Normal Items",
        ])
        #expect(container[.tags] == [
            "popular": "Popular Items",
            "normal": "Normal Items",
        ])
        
        #expect(container["webpage"] == "https://example.com/jane.doe/")
        #expect(container[.webpage] == "https://example.com/jane.doe/")
        #expect(try container.value(for: "webpage") == webpage)

        #expect(container["webpage"] == webpage)
        #expect(container[.webpage] == webpage)
    }
}
