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

#if canImport(UIKit) || canImport(AppKit)

import XCTest
@testable import TestCommon
@testable import WebAuthenticationUI

class OptionsTests: XCTestCase {
    func testOptionProperties() throws {
        let options: [WebAuthentication.Option] = [
            .login(hint: "foo"),
            .display("mobile"),
            .idpScope("foo bar"),
            .idp(url: URL(string: "https://example.com/idp")!),
            .prompt(.none),
            .maxAge(500),
            .state("ABC123"),
            .custom(key: "name", value: "value")
        ]
        
        XCTAssertEqual(options.additionalParameters, [
            "login_hint": "foo",
            "display": "mobile",
            "idp_scope": "foo bar",
            "idp": "https://example.com/idp",
            "prompt": "none",
            "name": "value"
        ])
        
        XCTAssertEqual(options.maxAge, 500)
        XCTAssertEqual(options.state, "ABC123")
        
        let context = try XCTUnwrap(options.context)
        XCTAssertEqual(context.state, "ABC123")
        XCTAssertEqual(context.maxAge, 500)
    }
    
    func testMissingOptions() throws {
        let options: [WebAuthentication.Option] = []

        XCTAssertNil(options.maxAge)
        XCTAssertNil(options.state)
        XCTAssertNil(options.context)
    }
    
    func testPrompts() throws {
        XCTAssertEqual(WebAuthentication.Option.Prompt.none.rawValue, "none")
        XCTAssertEqual(WebAuthentication.Option.Prompt.login.rawValue, "login")
        XCTAssertEqual(WebAuthentication.Option.Prompt.consent.rawValue, "consent")
        XCTAssertEqual(WebAuthentication.Option.Prompt.loginAndConsent.rawValue, "login consent")
    }
}

#endif
