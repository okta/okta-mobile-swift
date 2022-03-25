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

final class TokenInfoTests: XCTestCase {
    let accessTokenInfo = """
        {
            "active" : true,
            "token_type" : "Bearer",
            "scope" : "openid profile",
            "client_id" : "a9VpZDRCeFh3Nkk2VdYa",
            "username" : "john.doe@example.com",
            "exp" : 1451606400,
            "iat" : 1451602800,
            "sub" : "john.doe@example.com",
            "aud" : "https://example.okta.com",
            "iss" : "https://example.okta.com/oauth2/orsmsg0aWLdnF3spV0g3",
            "jti" : "AT.7P4KlczBYVcWLkxduEuKeZfeiNYkZIC9uGJ28Cc-YaI",
            "uid" : "00uid4BxXw6I6TV4m0g3"
        }
    """
    
    let refreshTokenInfo = """
        {
            "active" : true,
            "token_type" : "Bearer",
            "scope" : "openid profile email",
            "client_id" : "a9VpZDRCeFh3Nkk2VdYa",
            "username" : "john.doe@example.com",
            "exp" : 1451606400,
            "sub" : "john.doe@example.com",
            "device_id" : "q4SZgrA9sOeHkfst5uaa"
        }
    """

    func testAccessTokenInfo() throws {
        let info = try JSONDecoder().decode(TokenInfo.self, from: accessTokenInfo.data(using: .utf8)!)

        XCTAssertTrue(info.active ?? false)
        XCTAssertEqual(info.subject, "john.doe@example.com")
        XCTAssertEqual(info["username"], "john.doe@example.com")
    }

    func testRefreshTokenInfo() throws {
        let info = try JSONDecoder().decode(TokenInfo.self, from: refreshTokenInfo.data(using: .utf8)!)

        XCTAssertTrue(info.active ?? false)
        XCTAssertEqual(info.subject, "john.doe@example.com")
        XCTAssertEqual(info["client_id"], "a9VpZDRCeFh3Nkk2VdYa")
    }
    
    func testRawValueInitializer() throws {
        let data = [
            "active":false
        ]
        
        let info1 = TokenInfo(data)
        XCTAssertFalse(info1.active ?? true)
        
        let info2 = try XCTUnwrap(TokenInfo(rawValue: data))
        XCTAssertFalse(info2.active ?? true)
        
        XCTAssertEqual(info1.allClaims, info2.allClaims)
    }
}
