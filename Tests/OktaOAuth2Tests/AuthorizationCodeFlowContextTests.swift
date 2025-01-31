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
@testable import TestCommon
@testable import AuthFoundation
@testable import OktaOAuth2

class AuthorizationCodeFlowContextTests: XCTestCase {
    typealias Prompt = AuthorizationCodeFlow.Prompt
    typealias Context = AuthorizationCodeFlow.Context
    
    func testPrompts() throws {
        XCTAssertEqual(Prompt.none.rawValue, "none")
        XCTAssertEqual(Prompt.login.rawValue, "login")
        XCTAssertEqual(Prompt.consent.rawValue, "consent")
        XCTAssertEqual(Prompt.loginAndConsent.rawValue, "login consent")
        XCTAssertEqual(Prompt(rawValue: "NONE"), Prompt.none)
        XCTAssertEqual(Prompt(rawValue: "LOGIN"), .login)
        XCTAssertEqual(Prompt(rawValue: "CONSENT"), .consent)
        XCTAssertEqual(Prompt(rawValue: "LOGIN CONSENT"), .loginAndConsent)
        XCTAssertEqual(Prompt(rawValue: "consent login"), .loginAndConsent)
        XCTAssertNil(Prompt(rawValue: "something invalid"))
    }
    
    func testContextInitializers() throws {
        var context = Context()
        XCTAssertNotNil(context.state)
        XCTAssertNil(context.maxAge)
        
        context = Context(state: "foo")
        XCTAssertEqual(context.state, "foo")
        XCTAssertNil(context.maxAge)
        
        context = Context(maxAge: 100)
        XCTAssertNotNil(context.state)
        XCTAssertEqual(context.maxAge, 100)
        
        context = Context(additionalParameters: [
            "nonce": "some_nonce",
            "state": "baz",
            "acr_values": "urn:ietf:params:acr:nist:1 urn:ietf:params:acr:nist:2",
            "max_age": "50",
            "login_hint": "user@example.com",
            "id_token_hint": "abcdef123456",
            "ui_locales": "en-US fr",
            "claims_locales": "en-US fr",
            "display": "mobile",
            "prompt": "none",
            "name": "value",
        ])
        XCTAssertEqual(context.nonce, "some_nonce")
        XCTAssertEqual(context.state, "baz")
        XCTAssertEqual(context.acrValues, [
            "urn:ietf:params:acr:nist:1",
            "urn:ietf:params:acr:nist:2",
        ])
        XCTAssertEqual(context.maxAge, 50)
        XCTAssertEqual(context.loginHint, "user@example.com")
        XCTAssertEqual(context.idTokenHint, "abcdef123456")
        XCTAssertEqual(context.display, "mobile")
        XCTAssertEqual(context.prompt, Prompt.none)
        XCTAssertEqual(context.uiLocales, ["en-US", "fr"])
        XCTAssertEqual(context.claimsLocales, ["en-US", "fr"])
        XCTAssertEqual(context.additionalParameters?["name"] as? String, "value")
        XCTAssertEqual(Array(try XCTUnwrap(context.additionalParameters?.keys)), ["name"])
        
        context = Context(additionalParameters: ["prompt": "somethingInvalid"])
        XCTAssertNil(context.prompt)
        XCTAssertEqual(context.additionalParameters?["prompt"] as? String, "somethingInvalid")
    }
}

