//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

final class URLExtensionTests: XCTestCase {
    let redirectUri = URL(string: "com.example:/callback")!

    func testAuthorizationCodeFromURL() throws {
        typealias RedirectError = AuthorizationCodeFlow.RedirectError
        
        XCTAssertThrowsError(try URL(string: "urn:foo:bar")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123"))
        { error in
            XCTAssertEqual(error as? RedirectError, .unexpectedScheme("urn"))
        }
        
        XCTAssertThrowsError(try URL(string: "com.example:/")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123"))
        { error in
            XCTAssertEqual(error as? RedirectError, .missingQueryArguments)
        }
        
        XCTAssertThrowsError(try URL(string: "com.example:/?foo=bar")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123"))
        { error in
            XCTAssertEqual(error as? RedirectError, .invalidState(nil))
        }
        
        XCTAssertThrowsError(try URL(string: "com.example:/?foo=bar&state=abcd")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123"))
        { error in
            XCTAssertEqual(error as? RedirectError, .invalidState("abcd"))
        }
        
        XCTAssertThrowsError(try URL(string: "com.example:/?state=ABCD123&error=some_error&error_description=some+error+message")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123"))
        { error in
            let serverError = error as? OAuth2ServerError
            XCTAssertEqual(serverError?.code, .other(code: "some_error"))
            XCTAssertEqual(serverError?.description, "some error message")
        }
        
        XCTAssertThrowsError(try URL(string: "com.example:/?state=ABCD123")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123"))
        { error in
            XCTAssertEqual(error as? RedirectError, .missingAuthorizationCode)
        }

        let code = try URL(string: "com.example:/?state=ABCD123&code=foo")!
            .authorizationCode(redirectUri: redirectUri,
                               state: "ABCD123")
        XCTAssertEqual(code, "foo")
    }
}
