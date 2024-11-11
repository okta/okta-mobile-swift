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
@testable import OktaUtilities

final class VersionTests: XCTestCase {
    func testComponents() async throws {
        XCTAssertEqual(Version.Component(1), .numeric(1))
        XCTAssertEqual(Version.Component("abc"), .string("abc"))
        XCTAssertEqual(Version.Component("1"), .numeric(1))
    }

    func testEquality() async throws {
        XCTAssertEqual(Version("1.0.0"), Version("1.0.0"))
        XCTAssertEqual(Version("1.0.0"), Version("1.0"))
        XCTAssertEqual(Version("1.0.0"), Version("1"))
        XCTAssertEqual(Version("1.0.0"), Version("1"))
        XCTAssertEqual(Version("2.0.0-alpha"), Version("2.0.0-alpha"))
        XCTAssertEqual(Version(OperatingSystemVersion(majorVersion: 5, minorVersion: 0, patchVersion: 0)), "5.0.0")

        let version = Version("2.3.4-alpha")
        XCTAssertEqual(version.components[0], .numeric(2))
        XCTAssertEqual(version.components[1], .numeric(3))
        XCTAssertEqual(version.components[2], .numeric(4))
        XCTAssertEqual(version.components[3], .string("alpha"))
        XCTAssertEqual(version.major, 2)
        XCTAssertEqual(version.minor, 3)
        XCTAssertEqual(version.patch, 4)

        XCTAssertEqual(version.version(at: 3), .string("alpha"))
        
        let intValue: Int? = version.version(at: 3)
        XCTAssertNil(intValue)
        
        XCTAssertLessThan(Version("1.0.0"), Version("2.0.0"))
        XCTAssertLessThan(Version("1.0.0"), Version("1.1.0"))
        XCTAssertLessThan(Version("1.0.0"), Version("1.0.1"))
        XCTAssertLessThan(Version("1.1.20"), Version("1.2.0"))
    }
}
