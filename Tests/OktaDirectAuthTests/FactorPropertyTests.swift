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
    typealias ContinuationFactor = DirectAuthenticationFlow.ContinuationFactor

    func testLoginHint() throws {
        XCTAssertEqual(PrimaryFactor.password("foo").loginHintKey, "username")
        XCTAssertEqual(PrimaryFactor.otp(code: "123456").loginHintKey, "login_hint")
        XCTAssertEqual(PrimaryFactor.oob(channel: .push).loginHintKey, "login_hint")
        XCTAssertEqual(PrimaryFactor.webAuthn.loginHintKey, "login_hint")
    }
    
    func testPrimaryTokenParameters() throws {
        var parameters: [String: any APIRequestArgument] = [:]
        
        parameters = PrimaryFactor.password("foo").tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "password",
            "password": "foo"
        ])
        
        parameters = PrimaryFactor.otp(code: "123456").tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:otp",
            "otp": "123456"
        ])
        
        parameters = PrimaryFactor.oob(channel: .push).tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:oob"
        ])

        parameters = PrimaryFactor.webAuthn.tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:webauthn"
        ])
    }
    
    func testSecondaryTokenParameters() throws {
        var parameters: [String: any APIRequestArgument] = [:]

        parameters = SecondaryFactor.otp(code: "123456").tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "http://auth0.com/oauth/grant-type/mfa-otp",
            "otp": "123456"
        ])
        
        parameters = SecondaryFactor.oob(channel: .push).tokenParameters(currentStatus: .mfaRequired(.init(supportedChallengeTypes: nil, mfaToken: "abc123")))
        XCTAssertEqual(parameters.stringComponents, [
            "mfa_token": "abc123",
            "grant_type": "http://auth0.com/oauth/grant-type/mfa-oob"
        ])
        
        parameters = SecondaryFactor.oob(channel: .push).tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:oob"
        ])
        
        parameters = SecondaryFactor.webAuthn.tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:webauthn",
        ])
        
        parameters = SecondaryFactor.webAuthn.tokenParameters(currentStatus: .mfaRequired(.init(supportedChallengeTypes: nil, mfaToken: "abc123")))
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:mfa-webauthn",
            "mfa_token": "abc123",
        ])
    }
    
    func testContinuationTokenParameters() throws {
        var parameters: [String: any APIRequestArgument] = [:]
        
        parameters = ContinuationFactor.prompt(code: "123456")
            .tokenParameters(currentStatus: .continuation(
                .prompt(.init(oobResponse: .init(oobCode: "oob_abcd123",
                                                 expiresIn: 300,
                                                 interval: nil,
                                                 channel: .sms,
                                                 bindingMethod: .prompt,
                                                 bindingCode: "abcd123"),
                              mfaContext: nil))))
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:oob",
            "oob_code": "oob_abcd123",
            "binding_code": "123456",
        ])

        parameters = ContinuationFactor.webAuthn(response: .init(clientDataJSON: "",
                                                                 authenticatorData: "",
                                                                 signature: "",
                                                                 userHandle: nil)).tokenParameters(currentStatus: nil)
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:webauthn",
        ])

        let context = DirectAuthenticationFlow.ContinuationType.WebAuthnContext(
            request: try mock(from: .module, for: "challenge-webauthn", in: "MockResponses"),
            mfaContext: .init(supportedChallengeTypes: nil, mfaToken: "abc123"))
        parameters = ContinuationFactor.webAuthn(response: .init(clientDataJSON: "",
                                                                 authenticatorData: "",
                                                                 signature: "",
                                                                 userHandle: nil)).tokenParameters(currentStatus: .continuation(.webAuthn(context)))
                                                                    
        XCTAssertEqual(parameters.stringComponents, [
            "grant_type": "urn:okta:params:oauth:grant-type:mfa-webauthn",
            "mfa_token": "abc123",
        ])
    }
}
