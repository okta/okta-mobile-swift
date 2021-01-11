//
//  ScenarioTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-28.
//

import XCTest
@testable import OktaIdx

class ScenarioTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "https://example.com",
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
                        api: api,
                        queue: DispatchQueue.main)
    }
    
    func testScenario1() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://example.com/v1/interact", folderName: "Passcode", fileName: "01-interact-response")
        try session.expect("https://example.com/idp/idx/introspect", folderName: "Passcode", fileName: "02-introspect-response")
        try session.expect("https://example.com/idp/idx/identify", folderName: "Passcode", fileName: "03-identify-response")
        try session.expect("https://example.com/idp/idx/challenge/answer", folderName: "Passcode", fileName: "04-challenge-answer-response")
        try session.expect("https://example.com/oauth2/auszsfkYrgGCTilsV2o4/v1/token", folderName: "Passcode", fileName: "05-token-response")

        idx.start { (response, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            XCTAssertFalse(response!.isLoginSuccessful)
            
            let remediation = response?.remediation?.remediationOptions.first
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

                let remediation = response?.remediation?.remediationOptions.first
                XCTAssertNotNil(remediation)
                XCTAssertEqual(remediation?.name, "challenge-authenticator")
                XCTAssertEqual(remediation?.form.count, 2)
                
                XCTAssertEqual(remediation?.form[0].name, "credentials")
                XCTAssertEqual(remediation?.form[1].name, "stateHandle")

                let credentials = remediation?.form[0]
                XCTAssertTrue(credentials!.required)
                
                remediation?.proceed(with: ["credentials": [ "passcode": "password" ]]) { (response, error) in
                    XCTAssertNotNil(response)
                    XCTAssertNil(error)
                    XCTAssertTrue(response!.isLoginSuccessful)

                    response?.exchangeCode(completionHandler: { (token, error) in
                        XCTAssertNotNil(token)
                        XCTAssertNil(error)
                        
                        XCTAssertEqual(token?.tokenType, "Bearer")
                        XCTAssertEqual(token?.expiresIn, 3600)
                        XCTAssertEqual(token?.refreshToken, "WQcGbvjBpm2EA30-rPR7m6vGSzI8YMqNGYY9Qe14fT0")
                        completion.fulfill()
                    })
                }
            }
        }
        wait(for: [completion], timeout: 1)
    }
}
