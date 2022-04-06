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
import XCTest
@testable import AuthFoundation
import TestCommon

final class UserInfoTests: XCTestCase {
    let userInfo = "{\"sub\":\"00u2q5p3acVOXoSc04w5\",\"name\":\"Arthur Dent\",\"profile\":\"\",\"locale\":\"UK\",\"email\":\"arthur.dent@example.com\",\"nickname\":\"Earthling\",\"preferred_username\":\"arthur.dent@example.com\",\"given_name\":\"Arthur\",\"middle_name\":\"Phillip\",\"family_name\":\"Dent\",\"zoneinfo\":\"America/Los_Angeles\",\"updated_at\":1645121903,\"email_verified\":true,\"address\":{\"street_address\":\"155 Country Lane\",\"locality\":\"Cottington\",\"region\":\"Cottingshire County\",\"country\":\"UK\"}}"

    func testUserInfo() throws {
        let info = try JSONDecoder().decode(UserInfo.self, from: userInfo.data(using: .utf8)!)

        XCTAssertEqual(info.subject, "00u2q5p3acVOXoSc04w5")
        XCTAssertEqual(info.preferredUsername, "arthur.dent@example.com")
        XCTAssertEqual(info[.name], "Arthur Dent")
        XCTAssertEqual(info.userLocale, Locale(identifier: "UK"))
        XCTAssertEqual(info.timeZone?.identifier, "America/Los_Angeles")
        XCTAssertEqual(info.updatedAt?.timeIntervalSinceReferenceDate, 666814703)
        XCTAssertTrue(info.emailVerified!)
        XCTAssertEqual(info.address?["street_address"], "155 Country Lane")
        
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        if #available(iOS 15, macCatalyst 15, macOS 12.0, tvOS 15, watchOS 8, *) {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            formatter.locale = Locale(identifier: "UK")
            XCTAssertEqual(formatter.string(from: info.nameComponents), "Arthur Phillip Dent Earthling")
        }
        #endif
    }

    func testCoding() throws {
        let originalInfo = try UserInfo.jsonDecoder.decode(UserInfo.self, from: userInfo.data(using: .utf8)!)

        let data = try JSONEncoder().encode(originalInfo)
        
        let info = try UserInfo.jsonDecoder.decode(UserInfo.self, from: data)

        XCTAssertEqual(info.subject, "00u2q5p3acVOXoSc04w5")
        XCTAssertEqual(info.preferredUsername, "arthur.dent@example.com")
        XCTAssertEqual(info.givenName, "Arthur")
        XCTAssertEqual(info.familyName, "Dent")
        XCTAssertEqual(info[.name], "Arthur Dent")
        XCTAssertEqual(info.userLocale, Locale(identifier: "UK"))
        XCTAssertEqual(info.timeZone?.identifier, "America/Los_Angeles")
        XCTAssertEqual(info.updatedAt?.timeIntervalSinceReferenceDate, 666814703)
        XCTAssertTrue(info.emailVerified!)
        XCTAssertEqual(info.address?["street_address"], "155 Country Lane")
    }
    
    func testRawValueInitializer() throws {
        let data = [
            "sub":"ABC123",
            "name":"Arthur Dent"
        ]
        
        let info1 = UserInfo(data)
        XCTAssertEqual(info1.subject, "ABC123")
        XCTAssertEqual(info1.name, "Arthur Dent")
        
        let info2 = try XCTUnwrap(UserInfo(data))
        XCTAssertEqual(info2.subject, "ABC123")
        XCTAssertEqual(info2.name, "Arthur Dent")
        
        XCTAssertEqual(info1.allClaims.sorted(), info2.allClaims.sorted())
    }
}
