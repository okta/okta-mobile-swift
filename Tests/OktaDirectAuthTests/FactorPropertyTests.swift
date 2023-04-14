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
@testable import OktaDirectAuth

final class FactorPropertyTests: XCTestCase {
    typealias PrimaryFactor = DirectAuthenticationFlow.PrimaryFactor
    typealias SecondaryFactor = DirectAuthenticationFlow.SecondaryFactor
    
    func testLoginHint() throws {
        XCTAssertEqual(PrimaryFactor.password("foo").loginHintKey, "username")
        XCTAssertEqual(PrimaryFactor.otp(code: "123456").loginHintKey, "login_hint")
        XCTAssertEqual(PrimaryFactor.oob(channel: .push).loginHintKey, "login_hint")
    }
    
    func testGrantTypes() throws {
        XCTAssertEqual(PrimaryFactor.password("foo").grantType, .password)
        XCTAssertEqual(PrimaryFactor.otp(code: "123456").grantType, .otp)
        XCTAssertEqual(PrimaryFactor.oob(channel: .push).grantType, .oob)

        XCTAssertEqual(SecondaryFactor.otp(code: "123456").grantType, .otpMFA)
        XCTAssertEqual(SecondaryFactor.oob(channel: .push).grantType, .oobMFA)
    }
    
    func testTokenParameters() throws {
        XCTAssertEqual(PrimaryFactor.password("foo").tokenParameters as? [String: String], [
            "grant_type": "password",
            "password": "foo"
        ])
        XCTAssertEqual(PrimaryFactor.otp(code: "123456").tokenParameters as? [String: String], [
            "grant_type": "urn:okta:params:oauth:grant-type:otp",
            "otp": "123456"
        ])
        XCTAssertNil(PrimaryFactor.oob(channel: .push).tokenParameters)

        XCTAssertEqual(SecondaryFactor.otp(code: "123456").tokenParameters as? [String: String], [
            "grant_type": "http://auth0.com/oauth/grant-type/mfa-otp",
            "otp": "123456"
        ])
        XCTAssertNil(SecondaryFactor.oob(channel: .push).tokenParameters)
    }
}
