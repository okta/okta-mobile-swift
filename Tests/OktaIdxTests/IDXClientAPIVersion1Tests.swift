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

class IDXClientAPIVersion1Tests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "https://foo.oktapreview.com/oauth2/default",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    var context: IDXClient.Context!
    var session: URLSessionMock!
    var api: IDXClient.APIVersion1!
    var client: IDXClientAPIMock!
    
    override func setUpWithError() throws {
        session = URLSessionMock()
        context = IDXClient.Context(configuration: configuration, state: "state", interactionHandle: "foo", codeVerifier: "bar")
        client = IDXClientAPIMock(context: context)
        api = IDXClient.APIVersion1(with: configuration,
                                    session: session)
        api.client = client
    }

    func testInteractSuccess() throws {
        try session.expect("https://foo.oktapreview.com/oauth2/default/v1/interact", fileName: "interact-response")
        
        let completion = expectation(description: "Response")
        api.start(state: nil) { result in
            if case let Result.success(context) = result {
                XCTAssertNotNil(context)
                XCTAssertEqual(context.interactionHandle, "003Q14X7li")
            } else {
                XCTFail("Not successful")
            }
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }

    func testInteractFailure() throws {
        try session.expect("https://foo.oktapreview.com/v1/interact",
                           fileName: "interact-error-response",
                           statusCode: 400)
        
        let completion = expectation(description: "Response")
        api.start(state: nil) { result in
            if case let Result.failure(error) = result {
                XCTAssertEqual(error, .invalidResponseData)
            } else {
                XCTFail("Received success response when a failure was expected")
            }
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }

    func testIntrospectSuccess() throws {
        try session.expect("https://foo.oktapreview.com/idp/idx/introspect", fileName: "introspect-response")
        try session.expect("https://foo.oktapreview.com/idp/idx/cancel", fileName: "cancel-response")

        var response: Response!
        let completion = expectation(description: "Response")
        api.resume { result in
            if case let Result.success(responseValue) = result {
                response = responseValue
            } else {
                XCTFail("Error received when a success was expected")
            }
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
        
        guard response != nil else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(response.intent, .login)
        
        XCTAssertEqual(response.remediations.count, 2)
        
        let remediation = response.remediations.first
        XCTAssertEqual(remediation?.name, "identify")
        XCTAssertEqual(remediation?.href.absoluteString, "https://foo.oktapreview.com/idp/idx/identify")
        XCTAssertEqual(remediation?.method, "POST")
        XCTAssertEqual(remediation?.accepts, "application/ion+json; okta-version=1.0.0")
        XCTAssertEqual(remediation?.form.count, 2)
        XCTAssertEqual(remediation?.form.allFields.count, 3)

        var form = remediation?.form[0]
        XCTAssertEqual(form?.name, "identifier")
        XCTAssertEqual(form?.label, "Username")
        XCTAssertNil(form?.type)

        form = remediation?.form[1]
        XCTAssertEqual(form?.name, "rememberMe")
        XCTAssertEqual(form?.label, "Remember this device")
        XCTAssertEqual(form?.type, "boolean")

        form = remediation?.form.allFields[2]
        XCTAssertEqual(form?.name, "stateHandle")
        XCTAssertEqual(form?.isRequired, true)
        XCTAssertEqual(form?.isMutable, false)
        
        if let stringValue = form?.value as? String {
            XCTAssertEqual(stringValue, "02tYS1NHhCPLcOpT3GByBBRHmGU63p7LGRXJx5cOvp")
        } else {
            XCTFail("Form value \(String(describing: form?.value)) is not a string")
        }
        
        let cancelOption = response.remediations[.cancel]
        XCTAssertNotNil(cancelOption)
        XCTAssertEqual(cancelOption?.name, "cancel")
        XCTAssertEqual(cancelOption?.href.absoluteString, "https://foo.oktapreview.com/idp/idx/cancel")
        XCTAssertEqual(cancelOption?.method, "POST")
        XCTAssertEqual(cancelOption?.accepts, "application/ion+json; okta-version=1.0.0")
    }

    func testIntrospectFailure() throws {
        try session.expect("https://foo.oktapreview.com/v1/introspect",
                           fileName: "introspect-error-response",
                           statusCode: 400)
        
        let completion = expectation(description: "Response")
        api.resume { result in
            if case let Result.failure(error) = result {
                XCTAssertEqual(error, .invalidResponseData)
            } else {
                XCTFail("Received success response when a failure was expected")
            }
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }
    
    func testRedirectResultAuthenticated() throws {
        let redirectUrl = try XCTUnwrap(URL(string: """
                redirect:///uri?\
                interaction_code=qwe4xJasF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                state=state#_=_
                """))

        XCTAssertEqual(api.redirectResult(for: redirectUrl), .authenticated)
    }

    func testRedirectResultWithInvalidUrl() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect///uri"))

        XCTAssertEqual(api.redirectResult(for: redirectUrl), .invalidRedirectUrl)
    }

    func testRedirectResultWithInvalidScheme() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect.com:///uri"))

        XCTAssertEqual(api.redirectResult(for: redirectUrl), .invalidRedirectUrl)
    }

    func testRedirectResultWithInvalidState() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state1"))

        XCTAssertEqual(api.redirectResult(for: redirectUrl), .invalidContext)
    }

    func testRedirectResultWithRemediationError() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state&error=interaction_required"))

        XCTAssertEqual(api.redirectResult(for: redirectUrl), .remediationRequired)
    }

    func testRedirectResultWithEmptyResponse() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state"))

        XCTAssertEqual(api.redirectResult(for: redirectUrl), .invalidContext)
    }
}
