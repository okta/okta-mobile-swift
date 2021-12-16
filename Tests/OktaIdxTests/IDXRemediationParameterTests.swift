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
@testable import OktaIdx

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class IDXRemediationParameterTests: XCTestCase {
    let clientMock = IDXClientAPIMock(context: .init(configuration: .init(issuer: "https://example.com",
                                                                          clientId: "Bar",
                                                                          clientSecret: nil,
                                                                          scopes: ["scope"],
                                                                          redirectUri: "redirect:/"),
                                                     state: "state",
                                                     interactionHandle: "handle",
                                                     codeVerifier: "verifier"))

    func testFlatForm() throws {
        let response = try Response.response(
            client: clientMock,
            folderName: "Passcode",
            fileName: "02-introspect-response")
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
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        XCTAssertEqual(result["identifier"] as? String, "test@example.com")
        XCTAssertEqual(result["rememberMe"] as? Bool, true)
    }
    
    func testNestedForm() throws {
        let response = try Response.response(
            client: clientMock,
            folderName: "Passcode",
            fileName: "03-identify-response")
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
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        
        let credentialResult = result["credentials"] as? [String:Any]
        XCTAssertNotNil(credentialResult)
        XCTAssertEqual(credentialResult?["passcode"] as? String, "password")
    }

    func testNestedFormWithUnnamedOption() throws {
        let response = try Response.response(
            client: clientMock,
            folderName: "MFA-Email",
            fileName: "03-identify-response")
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
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        
        let authenticatorResult = result["authenticator"] as? [String:Any]
        XCTAssertNotNil(authenticatorResult)
        XCTAssertEqual(authenticatorResult?["id"] as? String, "aut3jya5v1oIgaLuV0g7")
        XCTAssertEqual(authenticatorResult?["methodType"] as? String, "email")
    }

    func testNestedFormWithCustomizedOption() throws {
        let response = try Response.response(
            client: clientMock,
            folderName: "MFA-SOP",
            fileName: "10-credential-enroll")
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
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        
        let authenticatorResult = result["authenticator"] as? [String:Any]
        XCTAssertNotNil(authenticatorResult)
        XCTAssertEqual(authenticatorResult?["id"] as? String, "aut3jya5v26pKeUb30g7")
        XCTAssertEqual(authenticatorResult?["methodType"] as? String, "sms")
        XCTAssertEqual(authenticatorResult?["phoneNumber"] as? String, "5551234567")
    }
}
