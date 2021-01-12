//
//  IDXClientAPIVersion1Tests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-14.
//

import XCTest
@testable import OktaIdx

class IDXClientAPIVersion1Tests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "https://foo.oktapreview.com",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    var session: URLSessionMock!
    var api: IDXClient.APIVersion1!
    
    override func setUpWithError() throws {
        session = URLSessionMock()
        api = IDXClient.APIVersion1(with: configuration,
                                    session: session)
    }

    func testInteractSuccess() throws {
        try session.expect("https://foo.oktapreview.com/oauth2/default/v1/interact", fileName: "interact-response")
        
        let completion = expectation(description: "Response")
        api.interact { (handle, error) in
            XCTAssertEqual(handle, "003Q14X7li")
            XCTAssertNil(error)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }

    func testInteractFailure() throws {
        try session.expect("https://foo.oktapreview.com/v1/interact",
                           fileName: "interact-error-response",
                           statusCode: 400)
        
        let completion = expectation(description: "Response")
        api.interact { (handle, error) in
            XCTAssertNil(handle)
            XCTAssertNotNil(error)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }

    func testIntrospectSuccess() throws {
        try session.expect("https://foo.oktapreview.com/idp/idx/introspect", fileName: "introspect-response")
        try session.expect("https://foo.oktapreview.com/idp/idx/cancel", fileName: "cancel-response")

        var response: IDXClient.Response!
        var completion = expectation(description: "Response")
        api.introspect("ABCeasyas123") { (responseValue, error) in
            XCTAssertNotNil(responseValue)
            XCTAssertNil(error)
            response = responseValue
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
        
        guard response != nil else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(response.stateHandle, "02tYS1NHhCPLcOpT3GByBBRHmGU63p7LGRXJx5cOvp")
        XCTAssertEqual(response.intent, "LOGIN")
        
        XCTAssertEqual(response.remediation?.type, "array")
        XCTAssertEqual(response.remediation?.remediationOptions.count, 1)
        
        let remediation = response.remediation?.remediationOptions.first
        XCTAssertEqual(remediation?.name, "identify")
        XCTAssertEqual(remediation?.href.absoluteString, "https://foo.oktapreview.com/idp/idx/identify")
        XCTAssertEqual(remediation?.method, "POST")
        XCTAssertEqual(remediation?.accepts, "application/ion+json; okta-version=1.0.0")
        XCTAssertEqual(remediation?.form.count, 3)
        
        var form = remediation?.form[0]
        XCTAssertEqual(form?.name, "identifier")
        XCTAssertEqual(form?.label, "Username")
        XCTAssertNil(form?.type)

        form = remediation?.form[1]
        XCTAssertEqual(form?.name, "rememberMe")
        XCTAssertEqual(form?.label, "Remember this device")
        XCTAssertEqual(form?.type, "boolean")

        form = remediation?.form[2]
        XCTAssertEqual(form?.name, "stateHandle")
        XCTAssertEqual(form?.required, true)
        XCTAssertEqual(form?.visible, false)
        XCTAssertEqual(form?.mutable, false)
        
        if let stringValue = form?.value as? String {
            XCTAssertEqual(stringValue, "02tYS1NHhCPLcOpT3GByBBRHmGU63p7LGRXJx5cOvp")
        } else {
            XCTFail("Form value \(String(describing: form?.value)) is not a string")
        }
        
        XCTAssertNotNil(api.cancelRemediationOption)
        XCTAssertEqual(api.cancelRemediationOption?.name, "cancel")
        XCTAssertEqual(api.cancelRemediationOption?.href.absoluteString, "https://foo.oktapreview.com/idp/idx/cancel")
        XCTAssertEqual(api.cancelRemediationOption?.method, "POST")
        XCTAssertEqual(api.cancelRemediationOption?.accepts, "application/ion+json; okta-version=1.0.0")
        
        completion = expectation(description: "Cancel response")
        api.cancel { (response, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }

    func testIntrospectFailure() throws {
        try session.expect("https://foo.oktapreview.com/v1/introspect",
                           fileName: "introspect-error-response",
                           statusCode: 400)
        
        let completion = expectation(description: "Response")
        api.introspect("ABCeasyas123") { (response, error) in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertTrue(error is IDXClientError)
            
            completion.fulfill()
        }
        wait(for: [completion], timeout: 1)
    }
}
