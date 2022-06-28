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

class IDXMessageCollectionTests: XCTestCase {
    var client: OAuth2Client!
    let urlSession = URLSessionMock()
    var flowMock: InteractionCodeFlowMock!

    override func setUpWithError() throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        let redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        let context = try InteractionCodeFlow.Context(interactionHandle: "handle", state: "state")
        
        flowMock = InteractionCodeFlowMock(context: context, client: client, redirectUri: redirectUri)
    }

    func testResponse() throws {
        let response = try XCTUnwrap(Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "invalid-password-response")))
        XCTAssertEqual(response.messages.count, 0)
        XCTAssertEqual(response.messages.allMessages.count, 1)
        
        let remediation = try XCTUnwrap(response.remediations[.enrollAuthenticator])
        XCTAssertEqual(remediation.messages.count, 0)
        XCTAssertEqual(remediation.messages.allMessages.count, 1)
        
        let field = try XCTUnwrap(remediation["credentials.passcode"])
        XCTAssertEqual(field.messages.count, 1)
        XCTAssertEqual(field.messages.allMessages.count, 1)
    }
}
