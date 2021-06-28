/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdx

class IDXRedirectTests: XCTestCase {

    typealias IDXRedirect = IDXClient.APIVersion1.Redirect
    
    func testRedirectWithInvalidUrl() throws {
        let redirectFromString = IDXRedirect(url: "")
        XCTAssertNil(redirectFromString)
        
        let redirectFromUrl = IDXRedirect(url: try XCTUnwrap(URL(string: "callback")))
        XCTAssertNil(redirectFromUrl)
    }
    
    func testRedirectWithInteractionCode() throws {
        let url = try XCTUnwrap(URL(string: "com.test:///login?state=1234&interaction_code=qwerty#_=_"))
        let redirect = try XCTUnwrap(IDXRedirect(url: url))

        XCTAssertEqual(redirect.url, url)
        XCTAssertEqual(redirect.scheme, "com.test")
        XCTAssertEqual(redirect.path, "/login")
        XCTAssertEqual(redirect.state, "1234")
        XCTAssertEqual(redirect.interactionCode, "qwerty")
        XCTAssertNil(redirect.error)
        XCTAssertNil(redirect.errorDescription)
    }
    
    func testRedirectWithInteractionError() throws {
        let url = "com.test:///login?error=interaction_required&error_description=Interaction+required#_=_"
        let redirect = try XCTUnwrap(IDXRedirect(url: url))

        XCTAssertEqual(redirect.url, try XCTUnwrap(URL(string: url)))
        XCTAssertEqual(redirect.scheme, "com.test")
        XCTAssertEqual(redirect.path, "/login")
        XCTAssertEqual(redirect.state, nil)
        XCTAssertEqual(redirect.interactionCode, nil)
        XCTAssertEqual(redirect.error, "interaction_required")
        // According to docs there's an issue with "+" character.
        // https://developer.apple.com/documentation/foundation/nsurlcomponents/1407752-queryitems
        XCTAssertEqual(redirect.errorDescription, "Interaction+required")
        XCTAssertTrue(redirect.interactionRequired)
    }

    func testRedirectComparison() throws {
        let firstUrl = "com.test:///login#_=_"
        let secondUrl = "com.test:/login#_=_"
        let firstRedirect = try XCTUnwrap(IDXRedirect(url: firstUrl))
        let secondRedirect = try XCTUnwrap(IDXRedirect(url: secondUrl))

        XCTAssertEqual(firstRedirect.path, "/login")
        XCTAssertEqual(firstRedirect.scheme, "com.test")
        
        XCTAssertEqual(firstRedirect.scheme, secondRedirect.scheme)
        XCTAssertEqual(firstRedirect.path, secondRedirect.path)
        XCTAssertNotEqual(firstRedirect.url, secondRedirect.url)

        XCTAssertNil(firstRedirect.state)
        XCTAssertFalse(firstRedirect.interactionRequired)
        XCTAssertNil(firstRedirect.interactionCode)
        XCTAssertNil(firstRedirect.error)
        XCTAssertNil(firstRedirect.errorDescription)
        
        XCTAssertEqual(firstRedirect.state, secondRedirect.state)
        XCTAssertEqual(firstRedirect.interactionRequired, secondRedirect.interactionRequired)
        XCTAssertEqual(firstRedirect.interactionCode, secondRedirect.interactionCode)
        XCTAssertEqual(firstRedirect.error, secondRedirect.error)
        XCTAssertEqual(firstRedirect.errorDescription, secondRedirect.errorDescription)
    }
}


