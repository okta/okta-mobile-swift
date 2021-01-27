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
        try session.expect("https://example.com/oauth2/default/v1/interact", folderName: "Passcode", fileName: "01-interact-response")
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

    func testScenario2() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://example.com/oauth2/default/v1/interact", folderName: "MFA-Email", fileName: "01-interact-response")
        try session.expect("https://example.com/idp/idx/introspect", folderName: "MFA-Email", fileName: "02-introspect-response")
        try session.expect("https://example.com/idp/idx/identify", folderName: "MFA-Email", fileName: "03-identify-response")
        try session.expect("https://example.com/idp/idx/challenge", folderName: "MFA-Email", fileName: "04-challenge-authenticator")
        try session.expect("https://example.com/idp/idx/challenge/answer", folderName: "MFA-Email", fileName: "05-challenge-authenticator")
//        try session.expect("https://example.com/oauth2/auszsfkYrgGCTilsV2o4/v1/token", folderName: "MFA-Email", fileName: "05-challenge-answer-invalid")

        // Start, takes us through interact & introspect
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

            // Identify ourselves as the given user, which returns the identify-response
            remediation?.proceed(with: ["identifier": "user@example.com", "rememberMe": false]) { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                guard let response = response else {
                    XCTFail()
                    return
                }

                XCTAssertFalse(response.isLoginSuccessful)

                let remediation = response.remediation?.remediationOptions.first
                XCTAssertNotNil(remediation)
                XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                XCTAssertEqual(remediation?.form.count, 2)
                
                XCTAssertEqual(remediation?.form[0].name, "authenticator")
                XCTAssertEqual(remediation?.form[1].name, "stateHandle")

                let credentials = remediation?.form[0]
                XCTAssertEqual(credentials?.type, "object")
                XCTAssertNotNil(credentials?.options)
                XCTAssertEqual(credentials?.options?.count, 3)
                
                let securityQuestion = credentials?.options?.filter { $0.label == "Security Question" }.first
                XCTAssertNotNil(securityQuestion)
                XCTAssertEqual(securityQuestion?.form?.count, 2)
                
                // Choose a authenticator challenge type
                remediation?.proceed(with: ["authenticator": securityQuestion as Any]) { (response, error) in
                    XCTAssertNotNil(response)
                    XCTAssertNil(error)
                    guard let response = response else {
                        XCTFail()
                        return
                    }

                    XCTAssertFalse(response.isLoginSuccessful)

                    let remediation = response.remediation?.remediationOptions.first
                    XCTAssertNotNil(remediation)
                    XCTAssertEqual(remediation?.name, "challenge-authenticator")
                    XCTAssertEqual(remediation?.form.count, 2)
                    
                    XCTAssertEqual(remediation?.form[0].name, "credentials")
                    XCTAssertEqual(remediation?.form[1].name, "stateHandle")
//                    TODO: MFA authentication tests aren't yet complete
//                    response?.exchangeCode(completionHandler: { (token, error) in
//                        XCTAssertNotNil(token)
//                        XCTAssertNil(error)
//
//                        XCTAssertEqual(token?.tokenType, "Bearer")
//                        XCTAssertEqual(token?.expiresIn, 3600)
//                        XCTAssertEqual(token?.refreshToken, "WQcGbvjBpm2EA30-rPR7m6vGSzI8YMqNGYY9Qe14fT0")
                        completion.fulfill()
//                    })
                }
            }
        }
        wait(for: [completion], timeout: 1)
    }
    
    /// Tests restarting a transaction
    func testScenario4() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://example.com/oauth2/default/v1/interact", folderName: "RestartTransaction", fileName: "01-interact-response")
        try session.expect("https://example.com/idp/idx/introspect", folderName: "RestartTransaction", fileName: "02-introspect-response")
        try session.expect("https://example.com/idp/idx/identify", folderName: "RestartTransaction", fileName: "03-identify-response")
        try session.expect("https://example.com/idp/idx/challenge", folderName: "RestartTransaction", fileName: "04-challenge-response")
        try session.expect("https://example.com/idp/idx/challenge/answer", folderName: "RestartTransaction", fileName: "05-challenge-answer-response")
        try session.expect("https://example.com/idp/idx/cancel", folderName: "RestartTransaction", fileName: "06-cancel-response")

        idx.start { (response, error) in
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            XCTAssertTrue(response?.canCancel ?? false)

            let remediation = response?.remediation?.remediationOptions.first
            XCTAssertEqual(remediation?.name, "identify")

            remediation?.proceed(with: ["identifier": "user@example.com"]) { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                XCTAssertTrue(response?.canCancel ?? false)

                let remediation = response?.remediation?.remediationOptions.first
                XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                
                let passcodeOption = remediation?.form
                    .filter { $0.name == "authenticator" }.first?
                    .options?.filter { $0.label == "Password" }.first
                XCTAssertNotNil(passcodeOption)

                remediation?.proceed(with: ["authenticator": passcodeOption!]) { (response, error) in
                    XCTAssertNotNil(response)
                    XCTAssertNil(error)
                    XCTAssertTrue(response?.canCancel ?? false)

                    let remediation = response?.remediation?.remediationOptions.first
                    XCTAssertEqual(remediation?.name, "challenge-authenticator")

                    let currentEnrollment = response?.currentAuthenticatorEnrollment
                    let related = remediation?.relatesTo?.first as? IDXClient.Authenticator.CurrentEnrollment
                    XCTAssertEqual(related, currentEnrollment)

                    remediation?.proceed(with: ["credentials": [ "passcode": "password" ]]) { (response, error) in
                        XCTAssertNotNil(response)
                        XCTAssertNil(error)
                        XCTAssertTrue(response?.canCancel ?? false)
                        
                        let remediation = response?.remediation?.remediationOptions.first
                        XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                        
                        let emailOption = remediation?.form
                            .filter { $0.name == "authenticator" }.first?
                            .options?.filter { $0.label == "Email" }.first
                        XCTAssertNotNil(emailOption)
                        
                        let authenticator = response?.authenticatorEnrollments?.first
                        let related = emailOption?.relatesTo as? IDXClient.Authenticator
                        XCTAssertEqual(related, authenticator)

                        response?.cancel() { (response, error) in
                            XCTAssertNotNil(response)
                            XCTAssertNil(error)
                            XCTAssertTrue(response?.canCancel ?? false)

                            let remediation = response?.remediation?.remediationOptions.first
                            XCTAssertEqual(remediation?.name, "identify")
                            
                            completion.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [completion], timeout: 1)
    }

}
