//
//  ScenarioTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-28.
//

import XCTest
@testable import OktaIdx

// https://oktawiki.atlassian.net/wiki/spaces/eng/pages/1364860951/Test+Plan+-+Interaction+code+grant+support+for+DevEx+SDKs#TestPlan-InteractioncodegrantsupportforDevExSDKs-TestScenarios:
class ScenarioTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "https://foo.oktapreview.com",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    var session: URLSessionMock!
    var api: IDXClient.APIVersion1!
    var idx: IDXClient!
    
    override func setUpWithError() throws {
        session = URLSessionMock()
        api = IDXClient.APIVersion1(with: configuration,
                                    session: session)
        idx = IDXClient(configuration: configuration,
                        api: api)
    }
    
    func testScenario1() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://foo.oktapreview.com/v1/interact", fileName: "interact-response")
        try session.expect("https://foo.oktapreview.com/idp/idx/introspect", fileName: "introspect-response")
        try session.expect("https://foo.oktapreview.com/idp/idx/identify", fileName: "identify-response")

        idx.start { (response, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            XCTAssertFalse(response!.isLoginSuccessful)
            
            let remediation = response?.remediation.remediationOptions.first
            XCTAssertNotNil(remediation)
            XCTAssertEqual(remediation?.name, "identify")
            XCTAssertEqual(remediation?.form.count, 3)
            XCTAssertEqual(remediation?.form[0].name, "identifier")
            XCTAssertEqual(remediation?.form[1].name, "rememberMe")
            XCTAssertEqual(remediation?.form[2].name, "stateHandle")

            remediation?.proceed(with: ["identifier": "user@example.com"]) { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                XCTAssertFalse(response!.isLoginSuccessful)

                let remediation = response?.remediation.remediationOptions.first
                XCTAssertNotNil(remediation)
                XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                XCTAssertEqual(remediation?.form.count, 2)
                
                XCTAssertEqual(remediation?.form[0].name, "authenticator")
                XCTAssertEqual(remediation?.form[1].name, "stateHandle")

                let authenticatorForm = remediation?.form[0]
                XCTAssertEqual(authenticatorForm?.options?.count, 3)
                
                let emailField = authenticatorForm?.options?[0]
                XCTAssertEqual(emailField?.label, "Email")
                XCTAssertNil(emailField?.name)
                
                let passwordField = authenticatorForm?.options?[1]
                XCTAssertEqual(passwordField?.label, "Password")
                XCTAssertNil(passwordField?.name)
                
                let questionField = authenticatorForm?.options?[2]
                XCTAssertEqual(questionField?.label, "Security Question")
                XCTAssertNil(questionField?.name)
                
                completion.fulfill()
            }
        }
        wait(for: [completion], timeout: 1)
    }
}
