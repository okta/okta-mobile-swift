//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaIdx

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class IDXAuthenticatorCollectionTests: XCTestCase {
    var client: OAuth2Client!
    let urlSession = URLSessionMock()
    var flowMock: IDXAuthenticationFlowMock!

    override func setUpWithError() throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        let redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "all",
                              session: urlSession)
        
        let context = try IDXAuthenticationFlow.Context(interactionHandle: "handle", state: "state")
        
        flowMock = IDXAuthenticationFlowMock(context: context, client: client, redirectUri: redirectUri)
    }

    func testCurrentAuthenticatorWithoutRelatesTo() throws {
        let response = try XCTUnwrap(Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "identify-single-form-response")))
        XCTAssertEqual(response.authenticators.count, 1)
        XCTAssertEqual(response.authenticators.first?.type, .password)
        
        let remediation = try XCTUnwrap(response.remediations[.identify])
        XCTAssertEqual(remediation.authenticators.count, 1)
        XCTAssertEqual(remediation.authenticators.first?.type, .password)
    }
    
    func testAuthenticatorEnrollmentWithoutId() throws {
        let response = try XCTUnwrap(Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "account-recovery")))
        
        let remediation = try XCTUnwrap(response.remediations[.selectAuthenticatorAuthenticate])
        let emailOption = try XCTUnwrap(remediation["authenticator"]?.options?.first)
        
        XCTAssertEqual(emailOption.label, "Email")
        
        let authenticator = try XCTUnwrap(emailOption.authenticator)
        XCTAssertEqual(authenticator.type, .email)
        XCTAssertEqual(authenticator.state, .enrolled)
    }
}
