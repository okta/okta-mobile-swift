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

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class IDXRemediationParameterTests: XCTestCase {
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

    func testFlatForm() throws {
        let response = try Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "02-introspect-response",
                       in: "MockResponses/Passcode"))
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediations["identify"],
              let identifier = remediationOption["identifier"],
              let rememberMe = remediationOption["rememberMe"] else
        {
            XCTFail("Could not find required fields")
            return
        }

        identifier.value = "test@example.com"
        rememberMe.value = true

        let result = try remediationOption.form.formValues()
        XCTAssertEqual(result["stateHandle"], "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        XCTAssertEqual(result["identifier"], "test@example.com")
        XCTAssertEqual(result["rememberMe"], true)
    }
    
    func testNestedForm() throws {
        let response = try Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "03-identify-response",
                       in: "MockResponses/Passcode"))
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediations["challenge-authenticator"],
              let credentials = remediationOption["credentials"],
              let passcode = credentials["passcode"] else
        {
            XCTFail("Could not find required fields")
            return
        }

        passcode.value = "password"

        let result = try remediationOption.form.formValues()
        XCTAssertEqual(result["stateHandle"], "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        XCTAssertEqual(result["credentials"]?["passcode"], "password")
        XCTAssertEqual(result["credentials"], .object(["passcode": "password"]))
    }

    func testNestedFormWithUnnamedOption() throws {
        let response = try Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "03-identify-response",
                       in: "MockResponses/MFA-Email"))
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediations["select-authenticator-authenticate"],
              let authenticator = remediationOption["authenticator"],
              let emailOption = authenticator.options?.filter({ $0.label == "Email" }).first else
        {
            XCTFail("Could not find required fields")
            return
        }

        authenticator.selectedOption = emailOption

        let result = try remediationOption.form.formValues()
        XCTAssertEqual(result["stateHandle"], "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        XCTAssertEqual(result["authenticator"]?["id"], "aut3jya5v1oIgaLuV0g7")
        XCTAssertEqual(result["authenticator"]?["methodType"], "email")
    }

    func testNestedFormWithCustomizedOption() throws {
        let response = try Response.response(
            flow: flowMock,
            data: data(from: .module,
                       for: "10-credential-enroll",
                       in: "MockResponses/MFA-SOP"))
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediations["select-authenticator-enroll"],
              let authenticator = remediationOption["authenticator"],
              let phoneOption = authenticator.options?.filter({ $0.label == "Phone" }).first,
              let methodType = phoneOption["methodType"],
              let smsType = methodType.options?.filter({ $0.label == "SMS" }).first,
              let phoneNumber = phoneOption["phoneNumber"] else
        {
            XCTFail("Could not find required fields")
            return
        }

        authenticator.selectedOption = phoneOption
        methodType.selectedOption = smsType
        phoneNumber.value = "5551234567"

        let result = try remediationOption.form.formValues()
        XCTAssertEqual(result["stateHandle"], "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        XCTAssertEqual(result["authenticator"]?["id"], "aut3jya5v26pKeUb30g7")
        XCTAssertEqual(result["authenticator"]?["methodType"], "sms")
        XCTAssertEqual(result["authenticator"]?["phoneNumber"], "5551234567")
    }
}
