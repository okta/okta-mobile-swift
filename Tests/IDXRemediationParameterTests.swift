/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

class IDXRemediationParameterTests: XCTestCase {
    typealias Parameters = IDXClient.Remediation.Parameters
    let clientMock = IDXClientAPIv1Mock(configuration: IDXClient.Configuration(issuer: "https://example.com",
                                                                               clientId: "Bar",
                                                                               clientSecret: nil,
                                                                               scopes: ["scope"],
                                                                               redirectUri: "redirect:/"))

    func testFlatForm() throws {
        let response = try IDXClient.Response.response(
            api: clientMock,
            folderName: "Passcode",
            fileName: "02-introspect-response")
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediation?["identify"],
              let identifier = remediationOption["identifier"],
              let stateHandle = remediationOption["stateHandle"],
              let rememberMe = remediationOption["rememberMe"] else
        {
            XCTFail("Could not find required fields")
            return
        }

        let params = Parameters()
        params[stateHandle] = "newValue"
        XCTAssertThrowsError(try remediationOption.formValues(using: params))

        params[identifier] = "test@example.com"
        params[rememberMe] = true
        XCTAssertThrowsError(try remediationOption.formValues(using: params))

        params[stateHandle] = nil

        let result = try remediationOption.formValues(using: params)
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        XCTAssertEqual(result["identifier"] as? String, "test@example.com")
        XCTAssertEqual(result["rememberMe"] as? Bool, true)
    }
    
    func testNestedForm() throws {
        let response = try IDXClient.Response.response(
            api: clientMock,
            folderName: "Passcode",
            fileName: "03-identify-response")
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediation?["challenge-authenticator"],
              let credentials = remediationOption["credentials"],
              let passcode = credentials["passcode"] else
        {
            XCTFail("Could not find required fields")
            return
        }

        let params = Parameters()
        params[passcode] = "password"

        let result = try remediationOption.formValues(using: params)
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        
        let credentialResult = result["credentials"] as? [String:Any]
        XCTAssertNotNil(credentialResult)
        XCTAssertEqual(credentialResult?["passcode"] as? String, "password")
    }

    func testNestedFormWithUnnamedOption() throws {
        let response = try IDXClient.Response.response(
            api: clientMock,
            folderName: "MFA-Email",
            fileName: "03-identify-response")
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediation?["select-authenticator-authenticate"],
              let authenticator = remediationOption["authenticator"],
              let emailOption = authenticator.options?.filter({ $0.label == "Email" }).first else
        {
            XCTFail("Could not find required fields")
            return
        }

        let params = Parameters()
        params[authenticator] = emailOption

        let result = try remediationOption.formValues(using: params)
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        
        let authenticatorResult = result["authenticator"] as? [String:Any]
        XCTAssertNotNil(authenticatorResult)
        XCTAssertEqual(authenticatorResult?["id"] as? String, "aut3jya5v1oIgaLuV0g7")
        XCTAssertEqual(authenticatorResult?["methodType"] as? String, "email")
    }

    func testNestedFormWithCustomizedOption() throws {
        let response = try IDXClient.Response.response(
            api: clientMock,
            folderName: "MFA-SOP",
            fileName: "10-credential-enroll")
        XCTAssertNotNil(response)
                
        guard let remediationOption = response.remediation?["select-authenticator-enroll"],
              let authenticator = remediationOption["authenticator"],
              let phoneOption = authenticator.options?.filter({ $0.label == "Phone" }).first,
              let methodType = phoneOption["methodType"],
              let phoneNumber = phoneOption["phoneNumber"] else
        {
            XCTFail("Could not find required fields")
            return
        }

        let params = Parameters()
        params[authenticator] = phoneOption
        params[methodType] = "sms"
        params[phoneNumber] = "5551234567"

        let result = try remediationOption.formValues(using: params)
        XCTAssertEqual(result["stateHandle"] as? String, "ahc52KautBHCANs3ScZjLfRcxFjP_N5mqOTYouqHFP")
        
        let authenticatorResult = result["authenticator"] as? [String:Any]
        XCTAssertNotNil(authenticatorResult)
        XCTAssertEqual(authenticatorResult?["id"] as? String, "aut3jya5v26pKeUb30g7")
        XCTAssertEqual(authenticatorResult?["methodType"] as? String, "sms")
        XCTAssertEqual(authenticatorResult?["phoneNumber"] as? String, "5551234567")
    }
}
