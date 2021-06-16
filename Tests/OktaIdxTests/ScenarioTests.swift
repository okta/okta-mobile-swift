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

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class ScenarioTests: XCTestCase {
    var configuration: IDXClient.Configuration!
    var context: IDXClient.Context!
    var session: URLSessionMock!
    var api: IDXClient.APIVersion1!
    
    override func setUpWithError() throws {
        session = URLSessionMock()
        configuration = IDXClient.Configuration(issuer: "https://example.com/oauth2/default",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
        context = IDXClient.Context(configuration: configuration,
                                    state: "state",
                                    interactionHandle: "foo",
                                    codeVerifier: "bar")

        api = IDXClient.APIVersion1(with: configuration,
                                    session: session)
    }
    
    func testScenario1() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://example.com/oauth2/default/v1/interact", folderName: "Passcode", fileName: "01-interact-response")
        try session.expect("https://example.com/idp/idx/introspect", folderName: "Passcode", fileName: "02-introspect-response")
        try session.expect("https://example.com/idp/idx/identify", folderName: "Passcode", fileName: "03-identify-response")
        try session.expect("https://example.com/idp/idx/challenge/answer", folderName: "Passcode", fileName: "04-challenge-answer-response")
        try session.expect("https://example.com/oauth2/auszsfkYrgGCTilsV2o4/v1/token", folderName: "Passcode", fileName: "05-token-response")

        IDXClient.start(with: api) { (client, error) in
            XCTAssertNotNil(client)
            XCTAssertNil(error)
            client?.resume { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                XCTAssertFalse(response!.isLoginSuccessful)
                
                let remediation = response?.remediations.first
                XCTAssertNotNil(remediation)
                XCTAssertEqual(remediation?.name, "identify")
                XCTAssertEqual(remediation?.form.count, 2)
                XCTAssertEqual(remediation?.form.allFields.count, 3)
                XCTAssertEqual(remediation?.form[0].name, "identifier")
                XCTAssertEqual(remediation?.form[1].name, "rememberMe")
                XCTAssertEqual(remediation?.form.allFields[2].name, "stateHandle")
                remediation?.form["identifier"]?.value = "user@example.com"
                
                remediation?.proceed { (response, error) in
                    XCTAssertNotNil(response)
                    XCTAssertNil(error)
                    XCTAssertFalse(response?.isLoginSuccessful ?? true)
                    
                    let remediation = response?.remediations.first
                    XCTAssertNotNil(remediation)
                    XCTAssertEqual(remediation?.name, "challenge-authenticator")
                    XCTAssertEqual(remediation?.form.count, 1)
                    
                    XCTAssertEqual(remediation?.form[0].name, "credentials")
                    XCTAssertEqual(remediation?.form.allFields[1].name, "stateHandle")
                    
                    let credentials = remediation?.form[0]
                    XCTAssertTrue(credentials?.isRequired ?? false)
                    remediation?.form["credentials"]?.form?["passcode"]?.value = "password"

                    remediation?.proceed { (response, error) in
                        XCTAssertNotNil(response)
                        XCTAssertNil(error)
                        XCTAssertTrue(response?.isLoginSuccessful ?? false)
                        
                        response?.exchangeCode { (token, error) in
                            XCTAssertNotNil(token)
                            XCTAssertNil(error)
                            
                            XCTAssertEqual(token?.tokenType, "Bearer")
                            XCTAssertEqual(token?.expiresIn, 3600)
                            XCTAssertEqual(token?.refreshToken, "CCY4M4fR3")
                            completion.fulfill()
                        }
                    }
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
//        try session.expect("https://example.com/idp/idx/challenge/answer", folderName: "MFA-Email", fileName: "05-challenge-authenticator")
        try session.expect("https://example.com/oauth2/auszsfkYrgGCTilsV2o4/v1/token", folderName: "MFA-Email", fileName: "05-challenge-answer-invalid")
        
        // Start, takes us through interact & introspect
        IDXClient.start(with: api) { (client, error) in
            XCTAssertNotNil(client)
            XCTAssertNil(error)
            client?.resume { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                XCTAssertFalse(response!.isLoginSuccessful)
                
                let remediation = response?.remediations.first
                XCTAssertNotNil(remediation)
                XCTAssertEqual(remediation?.name, "identify")
                XCTAssertEqual(remediation?.form.count, 2)
                XCTAssertEqual(remediation?.form.allFields.count, 3)

                let identifierField = remediation?.form[0]
                XCTAssertEqual(identifierField?.name, "identifier")

                let rememberMeField = remediation?.form[1]
                XCTAssertEqual(rememberMeField?.name, "rememberMe")

                let stateHandleField = remediation?.form.allFields[2]
                XCTAssertEqual(stateHandleField?.name, "stateHandle")
                
                identifierField?.value = "user@example.com"
                rememberMeField?.value = false
                
                // Identify ourselves as the given user, which returns the identify-response
                remediation?.proceed { (response, error) in
                    XCTAssertNotNil(response)
                    XCTAssertNil(error)
                    guard let response = response else {
                        XCTFail()
                        return
                    }
                    
                    XCTAssertFalse(response.isLoginSuccessful)
                    
                    let remediation = response.remediations.first
                    XCTAssertNotNil(remediation)
                    XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                    XCTAssertEqual(remediation?.form.count, 1)
                    XCTAssertEqual(remediation?.form.allFields.count, 2)

                    XCTAssertEqual(remediation?.form[0].name, "authenticator")
                    XCTAssertEqual(remediation?.form.allFields[1].name, "stateHandle")
                    
                    let credentials = remediation?.form[0]
                    XCTAssertEqual(credentials?.type, "object")
                    XCTAssertNotNil(credentials?.options)
                    XCTAssertEqual(credentials?.options?.count, 3)
                    
                    let securityQuestion = credentials?.options?.filter { $0.label == "Security Question" }.first
                    XCTAssertNotNil(securityQuestion)
                    XCTAssertEqual(securityQuestion?.form?.count, 0)
                    XCTAssertEqual(securityQuestion?.form?.allFields.count, 2)

                    credentials?.selectedOption = securityQuestion
                    
                    // Choose a authenticator challenge type
                    remediation?.proceed { (response, error) in
                        XCTAssertNotNil(response)
                        XCTAssertNil(error)
                        guard let response = response else {
                            XCTFail()
                            return
                        }
                        
                        XCTAssertFalse(response.isLoginSuccessful)
                        
                        let remediation = response.remediations.first
                        XCTAssertNotNil(remediation)
                        XCTAssertEqual(remediation?.name, "challenge-authenticator")
                        XCTAssertEqual(remediation?.form.count, 1)
                        XCTAssertEqual(remediation?.form.allFields.count, 2)

                        XCTAssertEqual(remediation?.form[0].name, "credentials")
                        XCTAssertEqual(remediation?.form.allFields[1].name, "stateHandle")
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

        IDXClient.start(with: api) { (client, error) in
            XCTAssertNotNil(client)
            XCTAssertNil(error)
            client?.resume { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                XCTAssertTrue(response?.canCancel ?? false)
                
                let remediation = response?.remediations.first
                XCTAssertEqual(remediation?.name, "identify")
                
                remediation?["identify"]?.value = "user@example.com"
                
                remediation?.proceed { (response, error) in
                    XCTAssertNotNil(response)
                    XCTAssertNil(error)
                    XCTAssertTrue(response?.canCancel ?? false)
                    
                    let remediation = response?.remediations.first
                    XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                    
                    let authenticator = remediation?.form
                        .filter { $0.name == "authenticator" }.first
                    let passcodeOption = authenticator?
                        .options?.filter { $0.label == "Password" }.first
                    XCTAssertNotNil(passcodeOption)
                    
                    authenticator?.selectedOption = passcodeOption
                    
                    remediation?.proceed { (response, error) in
                        XCTAssertNotNil(response)
                        XCTAssertNil(error)
                        XCTAssertTrue(response?.canCancel ?? false)
                        
                        let remediation = response?.remediations.first
                        XCTAssertEqual(remediation?.name, "challenge-authenticator")
                        
                        let currentEnrollment = response?.authenticators.current
                        let related = remediation?.authenticators.first
                        XCTAssertEqual(related, currentEnrollment)
                        
                        remediation?.form["credentials.passcode"]?.value = "password"
                        
                        remediation?.proceed { (response, error) in
                            XCTAssertNotNil(response)
                            XCTAssertNil(error)
                            XCTAssertTrue(response?.canCancel ?? false)
                            
                            let remediation = response?.remediations.first
                            XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                            XCTAssertEqual(remediation?.type, .selectAuthenticatorAuthenticate)

                            let emailOption = remediation?.form
                                .filter { $0.name == "authenticator" }.first?
                                .options?.filter { $0.label == "Email" }.first
                            XCTAssertNotNil(emailOption)
                            
                            let authenticator = response?.authenticators.enrolled.first
                            let related = emailOption?.authenticator
                            XCTAssertEqual(related, authenticator)
                            
                            response?.cancel() { (response, error) in
                                XCTAssertNotNil(response)
                                XCTAssertNil(error)
                                XCTAssertTrue(response?.canCancel ?? false)
                                
                                let remediation = response?.remediations.first
                                XCTAssertEqual(remediation?.name, "identify")
                                
                                completion.fulfill()
                            }
                        }
                    }
                }
            }
        }
        wait(for: [completion], timeout: 1)
    }
    
    func testScenario5() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://example.com/oauth2/default/v1/interact", folderName: "IdP", fileName: "01-interact-response")
        try session.expect("https://example.com/idp/idx/introspect", folderName: "IdP", fileName: "02-introspect-response")
        try session.expect("https://example.com/oauth2/default/v1/token", folderName: "IdP", fileName: "03-token-response")

        IDXClient.start(with: api) { (client, error) in
            XCTAssertNotNil(client)
            XCTAssertNil(error)
            client?.resume { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                let redirectUrl = URL(string: """
                        redirect:///uri?\
                        interaction_code=qwe4xJaJF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                        state=\(client!.context.state)#_=_
                        """)!
                
                XCTAssertTrue(response?.canCancel ?? false)
                XCTAssertNotNil(response?.remediations[.redirectIdp])
                XCTAssertNotNil(response?.remediations[.redirectIdp]?.href)
                XCTAssertFalse(response?.isLoginSuccessful ?? true)
                XCTAssertEqual(client?.redirectResult(for: redirectUrl), .authenticated)
                
                client?.exchangeCode(redirect: redirectUrl) { (token, error) in
                    XCTAssertNotNil(token)
                    XCTAssertNotNil(token?.idToken)
                    XCTAssertNotNil(token?.refreshToken)
                    XCTAssertNil(error)
                    
                    completion.fulfill()
                }
            }
        }
        
        wait(for: [completion], timeout: 2)
    }
    
    func testScenario6() throws {
        let completion = expectation(description: "Start")
        try session.expect("https://example.com/oauth2/default/v1/interact", folderName: "IdP", fileName: "01-interact-response")
        try session.expect("https://example.com/idp/idx/introspect", folderName: "IdP", fileName: "02-introspect-response")

        IDXClient.start(with: api) { (client, error) in
            XCTAssertNotNil(client)
            XCTAssertNil(error)
            client?.resume { (response, error) in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
                
                let redirectUrl = URL(string: """
                    redirect:///uri?\
                    state=\(client!.context.state)&\
                    error=interaction_required&\
                    error_description=Your+client+is+configured+to+use+the+interaction+code+flow+and+user+interaction+is+required+to+complete+the+request.#_=_
                    """)!
                
                XCTAssertTrue(response?.canCancel ?? false)
                XCTAssertNotNil(response?.remediations[.redirectIdp])
                XCTAssertNotNil(response?.remediations[.redirectIdp]?.href)
                XCTAssertFalse(response?.isLoginSuccessful ?? true)
                XCTAssertEqual(client?.redirectResult(for: redirectUrl), .remediationRequired)
                
                completion.fulfill()
            }
        }
        
        wait(for: [completion], timeout: 2)
    }
}
