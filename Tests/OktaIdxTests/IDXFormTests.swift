//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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
    let clientMock = IDXClientAPIMock(context: .init(configuration: .init(issuer: "https://example.com",
                                                                          clientId: "Bar",
                                                                          clientSecret: nil,
                                                                          scopes: ["scope"],
                                                                          redirectUri: "redirect:/"),
                                                     state: "state",
                                                     interactionHandle: "handle",
                                                     codeVerifier: "verifier"))

    func testSubscripts() throws {
        let form = IDXClient.Remediation.Form([.identifier, .stateHandle, .passwordCredentials])
        let remediation = IDXClient.Remediation.Test(client: clientMock,
                                                     name: "LOGIN",
                                                     method: "POST",
                                                     href: URL(string: "https://example.com")!,
                                                     accepts: nil,
                                                     form: form)
        XCTAssertEqual(form.fields.count, 2)
        XCTAssertEqual(form.allFields.count, 3)
        
        // Ensure private fields aren't accessible
        XCTAssertNil(form["stateHandle"])
        XCTAssertNil(remediation["stateHandle"])
        XCTAssertNil(form.stateHandle)
        XCTAssertNil(remediation.stateHandle)

        // Check top-level fields
        XCTAssertEqual(form["identifier"]?.name, "identifier")
        XCTAssertEqual(remediation["identifier"]?.name, "identifier")
        XCTAssertEqual(form.identifier?.name, "identifier")
        XCTAssertEqual(remediation.identifier?.name, "identifier")

        // Check top-level object fields
        XCTAssertEqual(form["credentials"]?.name, "credentials")
        XCTAssertEqual(remediation["credentials"]?.name, "credentials")
        XCTAssertEqual(form.credentials?.name, "credentials")
        XCTAssertEqual(remediation.credentials?.name, "credentials")
        XCTAssertEqual(form.credentials?.form?.fields.count, 1)
        XCTAssertEqual(form.credentials?.form?.allFields.count, 1)
        
        // Check nested fields
        XCTAssertEqual(form["credentials"]?["passcode"]?.name, "passcode")
        XCTAssertEqual(form["credentials.passcode"]?.name, "passcode")
        XCTAssertEqual(remediation["credentials.passcode"]?.name, "passcode")
        XCTAssertEqual(form.credentials?.form?.passcode?.name, "passcode")
        XCTAssertEqual(form.credentials?.passcode?.name, "passcode")
        XCTAssertEqual(remediation.credentials?.passcode?.name, "passcode")
    }
}
