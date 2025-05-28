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

final class MockAccessTokenValidator: TokenHashValidator, Sendable {
    func validate(_ accessToken: String, idToken: JWT) throws {}
}

struct MockIDTokenValidator: IDTokenValidator, Sendable {
    var issuedAtGraceInterval: TimeInterval = 300
    func validate(token: JWT, issuer: URL, clientId: String, context: (any IDTokenValidatorContext)?) throws {}
}

struct MockJWKValidator: JWKValidator {
    func validate(token: JWT, using keySet: JWKS) throws -> Bool {
        true
    }
}

class ScenarioTests: XCTestCase {
    var issuer: URL!
    var client: OAuth2Client!
    var urlSession = URLSessionMock()
    var flow: InteractionCodeFlow!
    
    override func setUpWithError() throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockAccessTokenValidator()

        issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        let redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "0ZczewGCFPlxNYYcLq5i",
                              scope: "openid profile",
                              redirectUri: redirectUri,
                              session: urlSession)

        flow = try InteractionCodeFlow(client: client)
    }
    
    override func tearDownWithError() throws {
        client = nil
        flow = nil
    }
    
    func testScenario1() throws {
        let completion = expectation(description: "Start")
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "01-interact-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "02-introspect-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/idp/idx/identify",
                          data: try data(from: .module,
                                         for: "03-identify-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/idp/idx/challenge/answer",
                          data: try data(from: .module,
                                         for: "04-challenge-answer-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/oauth2/auszsfkYrgGCTilsV2o4/v1/token",
                          data: try data(from: .module,
                                         for: "05-token-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=0ZczewGCFPlxNYYcLq5i",
                          data: try data(from: .module, for: "keys"),
                          contentType: "application/json")

        flow.start { result in
            guard case let Result.success(response) = result else {
                XCTFail("Received a failure when a success was expected")
                return
            }
            XCTAssertFalse(response.isLoginSuccessful)
            
            let remediation = response.remediations.first
            XCTAssertEqual(remediation?.name, "identify")
            XCTAssertEqual(remediation?.form.count, 2)
            XCTAssertEqual(remediation?.form.allFields.count, 3)
            XCTAssertEqual(remediation?.form[0].name, "identifier")
            XCTAssertEqual(remediation?.form[1].name, "rememberMe")
            XCTAssertEqual(remediation?.form.allFields[2].name, "stateHandle")
            remediation?.form["identifier"]?.value = "user@example.com"
            
            remediation?.proceed { result in
                guard case let Result.success(response) = result else {
                    XCTFail("Received a failure when a success was expected")
                    return
                }
                
                XCTAssertFalse(response.isLoginSuccessful)
                
                let remediation = response.remediations.first
                XCTAssertEqual(remediation?.name, "challenge-authenticator")
                XCTAssertEqual(remediation?.form.count, 1)
                
                XCTAssertEqual(remediation?.form[0].name, "credentials")
                XCTAssertEqual(remediation?.form.allFields[1].name, "stateHandle")
                
                let credentials = remediation?.form[0]
                XCTAssertTrue(credentials?.isRequired ?? false)
                remediation?.form["credentials"]?.form?["passcode"]?.value = "password"
                
                remediation?.proceed { result in
                    guard case let Result.success(response) = result else {
                        XCTFail("Received a failure when a success was expected")
                        return
                    }
                    
                    XCTAssertTrue(response.isLoginSuccessful)

                    response.finish { result in
                        guard case let Result.success(token) = result else {
                            XCTFail("Received a failure when a success was expected")
                            return
                        }
                        
                        XCTAssertEqual(token.tokenType, "Bearer")
                        XCTAssertEqual(token.expiresIn, 3600)
                        XCTAssertEqual(token.refreshToken, "CCY4M4fR3")
                        completion.fulfill()
                    }
                }
            }
        }
        wait(for: [completion], timeout: 1)
    }

    func testScenario1Async() async throws {
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "01-interact-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "02-introspect-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/idp/idx/identify",
                          data: try data(from: .module,
                                         for: "03-identify-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/idp/idx/challenge/answer",
                          data: try data(from: .module,
                                         for: "04-challenge-answer-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/oauth2/auszsfkYrgGCTilsV2o4/v1/token",
                          data: try data(from: .module,
                                         for: "05-token-response",
                                         in: "Passcode"))
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=0ZczewGCFPlxNYYcLq5i",
                          data: try data(from: .module, for: "keys"),
                          contentType: "application/json")

        var response = try await flow.start()
        
        XCTAssertFalse(response.isLoginSuccessful)
                
        var remediation = try XCTUnwrap(response.remediations[.identify])
        remediation["identifier"]?.value = "user@example.com"
                
        response = try await remediation.proceed()
        XCTAssertFalse(response.isLoginSuccessful)
                    
        remediation = try XCTUnwrap(response.remediations[.challengeAuthenticator])
        remediation["credentials.passcode"]?.value = "password"
        response = try await remediation.proceed()
        
        XCTAssertTrue(response.isLoginSuccessful)
                        
        let token = try await response.finish()

        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.expiresIn, 3600)
        XCTAssertEqual(token.refreshToken, "CCY4M4fR3")
    }

    func testScenario2() throws {
        let completion = expectation(description: "Start")
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module,
                                         for: "openid-configuration"))
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "01-interact-response",
                                         in: "MFA-Email"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "02-introspect-response",
                                         in: "MFA-Email"))
        urlSession.expect("https://example.com/idp/idx/identify",
                          data: try data(from: .module,
                                         for: "03-identify-response",
                                         in: "MFA-Email"))
        urlSession.expect("https://example.com/idp/idx/challenge",
                          data: try data(from: .module,
                                         for: "04-challenge-authenticator",
                                         in: "MFA-Email"))

        flow.start { result in
            guard case let Result.success(response) = result else {
                XCTFail("Received a failure when a success was expected")
                completion.fulfill()
                return
            }
            
            XCTAssertFalse(response.isLoginSuccessful)
            
            let remediation = response.remediations.first
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
            remediation?.proceed { result in
                guard case let Result.success(response) = result else {
                    XCTFail("Received a failure when a success was expected")
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
                remediation?.proceed { result in
                    guard case let Result.success(response) = result else {
                        XCTFail("Received a failure when a success was expected")
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
        wait(for: [completion], timeout: 1)
    }
    
    /// Tests restarting a transaction
    func testScenario4() throws {
        let completion = expectation(description: "Start")

        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module,
                                         for: "openid-configuration"))
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "01-interact-response",
                                         in: "RestartTransaction"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "02-introspect-response",
                                         in: "RestartTransaction"))
        urlSession.expect("https://example.com/idp/idx/identify",
                          data: try data(from: .module,
                                         for: "03-identify-response",
                                         in: "RestartTransaction"))
        urlSession.expect("https://example.com/idp/idx/challenge",
                          data: try data(from: .module,
                                         for: "04-challenge-response",
                                         in: "RestartTransaction"))
        urlSession.expect("https://example.com/idp/idx/challenge/answer",
                          data: try data(from: .module,
                                         for: "05-challenge-answer-response",
                                         in: "RestartTransaction"))
        urlSession.expect("https://example.com/idp/idx/cancel",
                          data: try data(from: .module,
                                         for: "06-cancel-response",
                                         in: "RestartTransaction"))

        flow.start { result in
            guard case let Result.success(response) = result else {
                XCTFail("Received a failure when a success was expected")
                completion.fulfill()
                return
            }

            XCTAssertTrue(response.canRestart)

            let remediation = response.remediations.first
            XCTAssertEqual(remediation?.name, "identify")

            remediation?["identify"]?.value = "user@example.com"

            remediation?.proceed { result in
                guard case let Result.success(response) = result else {
                    XCTFail("Received a failure when a success was expected")
                    return
                }

                XCTAssertTrue(response.canRestart)

                let remediation = response.remediations.first
                XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")

                let authenticator = remediation?.form
                    .filter { $0.name == "authenticator" }.first
                let passcodeOption = authenticator?
                    .options?.filter { $0.label == "Password" }.first
                XCTAssertNotNil(passcodeOption)

                authenticator?.selectedOption = passcodeOption

                remediation?.proceed { result in
                    guard case let Result.success(response) = result else {
                        XCTFail("Received a failure when a success was expected")
                        return
                    }

                    XCTAssertTrue(response.canRestart)

                    let remediation = response.remediations.first
                    XCTAssertEqual(remediation?.name, "challenge-authenticator")

                    let currentEnrollment = response.authenticators.current
                    let related = remediation?.authenticators.first
                    XCTAssertEqual(related, currentEnrollment)

                    remediation?.form["credentials.passcode"]?.value = "password"

                    remediation?.proceed { result in
                        guard case let Result.success(response) = result else {
                            XCTFail("Received a failure when a success was expected")
                            return
                        }

                        XCTAssertTrue(response.canRestart)

                        let remediation = response.remediations.first
                        XCTAssertEqual(remediation?.name, "select-authenticator-authenticate")
                        XCTAssertEqual(remediation?.type, .selectAuthenticatorAuthenticate)

                        let emailOption = remediation?.form
                            .filter { $0.name == "authenticator" }.first?
                            .options?.filter { $0.label == "Email" }.first
                        XCTAssertNotNil(emailOption)

                        let authenticator = response.authenticators.enrolled.first
                        let related = emailOption?.authenticator
                        XCTAssertEqual(related, authenticator)

                        response.restart { result in
                            guard case let Result.success(response) = result else {
                                XCTFail("Received a failure when a success was expected")
                                return
                            }

                            XCTAssertTrue(response.canRestart)

                            let remediation = response.remediations.first
                            XCTAssertEqual(remediation?.name, "identify")

                            completion.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [completion], timeout: 1)
    }
    
    func testScenario5() throws {
        let completion = expectation(description: "Start")
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "01-interact-response",
                                         in: "IdP"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "02-introspect-response",
                                         in: "IdP"))
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module,
                                         for: "openid-configuration"))
        urlSession.expect("https://example.com/oauth2/default/v1/token",
                          data: try data(from: .module,
                                         for: "03-token-response",
                                         in: "IdP"))
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=0ZczewGCFPlxNYYcLq5i",
                          data: try data(from: .module, for: "keys"),
                          contentType: "application/json")

        let flow = try XCTUnwrap(flow)
        flow.start { result in
            guard case let Result.success(response) = result else {
                XCTFail("Received a failure when a success was expected")
                completion.fulfill()
                return
            }
            
            let redirectUrl = URL(string: """
                        redirect:///uri?\
                        interaction_code=qwe4xJaJF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                        state=\(flow.context?.state ?? "Missing")#_=_
                        """)!
            
            XCTAssertTrue(response.canRestart)
            XCTAssertNotNil(response.remediations[.redirectIdp])
            XCTAssertNotNil(response.remediations[.redirectIdp]?.href)
            XCTAssertFalse(response.isLoginSuccessful)

            flow.resume(with: redirectUrl) { result in
                switch result {
                case .success(let status):
                    switch status {
                    case .success(let token):
                        XCTAssertNotNil(token.idToken)
                        XCTAssertNotNil(token.refreshToken)
                    case .interactionRequired(_):
                        XCTFail("Interaction required")
                    }
                case .failure(let error):
                    XCTFail("Resume should not have failed: \(error)")
                }

                completion.fulfill()
            }
        }
        
        wait(for: [completion], timeout: 2)
    }
    
    func testScenario6() throws {
        let completion = expectation(description: "Start")
        urlSession.expect("https://example.com/oauth2/default/.well-known/openid-configuration",
                          data: try data(from: .module,
                                         for: "openid-configuration"))
        urlSession.expect("https://example.com/oauth2/default/v1/interact",
                          data: try data(from: .module,
                                         for: "01-interact-response",
                                         in: "IdP"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "02-introspect-response",
                                         in: "IdP"))
        urlSession.expect("https://example.com/idp/idx/introspect",
                          data: try data(from: .module,
                                         for: "multiple-select-authenticator-authenticate"))

        let flow = try XCTUnwrap(flow)
        flow.start { result in
            guard case let Result.success(response) = result else {
                XCTFail("Received a failure when a success was expected")
                completion.fulfill()
                return
            }
            
            let redirectUrl = URL(string: """
                    redirect:///uri?\
                    state=\(flow.context?.state ?? "Missing")&\
                    error=interaction_required&\
                    error_description=Your+client+is+configured+to+use+the+interaction+code+flow+and+user+interaction+is+required+to+complete+the+request.#_=_
                    """)!
            
            XCTAssertTrue(response.canRestart)
            XCTAssertNotNil(response.remediations[.redirectIdp])
            XCTAssertNotNil(response.remediations[.redirectIdp]?.href)
            XCTAssertFalse(response.isLoginSuccessful)
            flow.resume(with: redirectUrl) { result in
                switch result {
                case .success(let status):
                    switch status {
                    case .success(_):
                        XCTFail("Expected failure, got success")
                    case .interactionRequired(let response):
                        XCTAssertNotNil(response.remediations[.selectAuthenticatorAuthenticate])
                    }
                case .failure(let error):
                    XCTFail("Resume should not have failed: \(error)")
                }

                completion.fulfill()
            }
        }
        
        wait(for: [completion], timeout: 2)
    }
}
