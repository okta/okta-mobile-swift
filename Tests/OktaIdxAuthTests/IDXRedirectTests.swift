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
@testable import OktaIdxAuth

class IDXRedirectTests: XCTestCase {
    var redirectUri: URL!

    override func setUpWithError() throws {
        redirectUri = try URL(requiredString: "com.test:///login")
    }

    func testRedirectWithInteractionCode() throws {
        let url = try XCTUnwrap(URL(string: "com.test:///login?state=1234&interaction_code=qwerty#_=_"))
        let redirect = try XCTUnwrap(try url.interactionCode(redirectUri: redirectUri, state: "1234"))
        XCTAssertEqual(redirect, .code("qwerty"))
    }

    func testRedirectWithInteractionError() throws {
        let url = try XCTUnwrap(URL(string: "com.test:///login?error=interaction_required&error_description=Interaction+required#_=_"))
        let redirect = try XCTUnwrap(try url.interactionCode(redirectUri: redirectUri, state: "1234"))
        XCTAssertEqual(redirect, .interactionRequired)
    }
}
