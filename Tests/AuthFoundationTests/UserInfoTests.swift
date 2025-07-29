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
import TestCommon

@Suite("UserInfo Tests")
struct UserInfoTests {
    let userInfo = "{\"sub\":\"00u2q5p3acVOXoSc04w5\",\"name\":\"Arthur Dent\",\"profile\":\"\",\"locale\":\"UK\",\"email\":\"arthur.dent@example.com\",\"nickname\":\"Earthling\",\"preferred_username\":\"arthur.dent@example.com\",\"given_name\":\"Arthur\",\"middle_name\":\"Phillip\",\"family_name\":\"Dent\",\"zoneinfo\":\"America/Los_Angeles\",\"updated_at\":1645121903,\"email_verified\":true,\"address\":{\"street_address\":\"155 Country Lane\",\"locality\":\"Cottington\",\"region\":\"Cottingshire County\",\"country\":\"UK\"}}"

    @Test("Initialize and test UserInfo from a JSON string")
    func testUserInfo() throws {
        let info = try JSONDecoder().decode(UserInfo.self, from: userInfo.data(using: .utf8)!)

        #expect(info.subject == "00u2q5p3acVOXoSc04w5")
        #expect(info.preferredUsername == "arthur.dent@example.com")
        #expect(info[.name] == "Arthur Dent")
        #expect(info.userLocale == Locale(identifier: "UK"))
        #expect(info.timeZone?.identifier == "America/Los_Angeles")
        #expect(info.updatedAt?.timeIntervalSinceReferenceDate == 666814703)
        #expect(info.emailVerified == true)
        #expect(info.address?["street_address"] as? String == "155 Country Lane")
        
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.10) && os(visionOS))
        if #available(iOS 15, macCatalyst 15, macOS 12.0, tvOS 15, watchOS 8, *) {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            formatter.locale = Locale(identifier: "UK")
            #expect(formatter.string(from: info.nameComponents) == "Arthur Phillip Dent Earthling")
        }
        #endif
    }

    @Test("UserInfo encoder/decoder")
    func testCoding() throws {
        let originalInfo = try UserInfo.jsonDecoder.decode(UserInfo.self, from: userInfo.data(using: .utf8)!)

        let data = try JSONEncoder().encode(originalInfo)
        
        let info = try UserInfo.jsonDecoder.decode(UserInfo.self, from: data)

        #expect(info.subject == "00u2q5p3acVOXoSc04w5")
        #expect(info.preferredUsername == "arthur.dent@example.com")
        #expect(info.givenName == "Arthur")
        #expect(info.familyName == "Dent")
        #expect(info[.name] == "Arthur Dent")
        #expect(info.userLocale == Locale(identifier: "UK"))
        #expect(info.timeZone?.identifier == "America/Los_Angeles")
        #expect(info.updatedAt?.timeIntervalSinceReferenceDate == 666814703)
        #expect(info.emailVerified == true)
        #expect(info.address?["street_address"] as? String == "155 Country Lane")
    }
    
    @Test("Initialize UserInfo from a raw value")
    func testRawValueInitializer() throws {
        let data = [
            "sub":"ABC123",
            "name":"Arthur Dent"
        ]
        
        let info1 = UserInfo(data)
        #expect(info1.subject == "ABC123")
        #expect(info1.name == "Arthur Dent")
        
        let info2 = UserInfo(data)
        #expect(info2.subject == "ABC123")
        #expect(info2.name == "Arthur Dent")
        
        #expect(info1.allClaims.sorted() == info2.allClaims.sorted())
    }
}
