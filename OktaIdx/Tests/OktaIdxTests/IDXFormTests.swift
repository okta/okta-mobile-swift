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

class IDXFormTests: XCTestCase {
    var client: OAuth2Client!
    let urlSession = URLSessionMock()
    var flowMock: InteractionCodeFlowMock!

    override func setUpWithError() throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        let redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              session: urlSession)
        flowMock = InteractionCodeFlowMock(client: client, redirectUri: redirectUri)
    }
    
    func testSubscripts() throws {
        let data = try XCTUnwrap("""
        {
            "rel": ["create-form"],
            "name": "identify",
            "href": "https://example.com/idp/idx/identify",
            "method": "POST",
            "value": [{
                "name": "identifier",
                "label": "Username"
            },
            {
               "form" : {
                  "value" : [
                     {
                        "label" : "Password",
                        "name" : "passcode",
                        "secret" : true
                     }
                  ]
               },
               "name" : "credentials",
               "required" : true,
               "type" : "object"
            },
            {
                "name": "rememberMe",
                "type": "boolean",
                "label": "Remember this device"
            }, {
                "name": "stateHandle",
                "required": true,
                "value": "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP",
                "visible": false,
                "mutable": false
            }],
            "accepts": "application/ion+json; okta-version=1.0.0"
        }
        """.data(using: .utf8))
        
        let v1Form = try JSONDecoder().decode(IonForm.self, from: data)
        let remediation = try XCTUnwrap(Remediation.makeRemediation(flow: flowMock, ion: v1Form))
        let form = remediation.form
        
        XCTAssertEqual(form.fields.count, 3)
        XCTAssertEqual(form.allFields.count, 4)
        
        // Ensure private fields aren't accessible
        XCTAssertNil(form["stateHandle"])
        XCTAssertNil(remediation["stateHandle"])

        // Check top-level fields
        XCTAssertEqual(form["identifier"]?.name, "identifier")
        XCTAssertEqual(remediation["identifier"]?.name, "identifier")

        // Check top-level object fields
        XCTAssertEqual(form["credentials"]?.name, "credentials")
        XCTAssertEqual(remediation["credentials"]?.name, "credentials")
        
        // Check nested fields
        XCTAssertEqual(form["credentials"]?["passcode"]?.name, "passcode")
        XCTAssertEqual(form["credentials.passcode"]?.name, "passcode")
        XCTAssertEqual(remediation["credentials.passcode"]?.name, "passcode")
    }
}
