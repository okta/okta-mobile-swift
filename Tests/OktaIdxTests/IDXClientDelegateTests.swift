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

class IDXClientDelegateTests: XCTestCase {
    let context = IDXClient.Context(configuration: IDXClient.Configuration(issuer: "issuer",
                                                                           clientId: "clientId",
                                                                           clientSecret: "clientSecret",
                                                                           scopes: ["all"],
                                                                           redirectUri: "redirect:/uri"),
                                    state: "state",
                                    interactionHandle: "foo",
                                    codeVerifier: "bar")
    var client: IDXClient!
    var api: IDXClientAPIv1Mock!
    var remediationOption: Remediation!
    var response: Response!
    var redirectUrl: URL!
    var token: Token!
    let delegate = DelegateRecorder()
    let error = IDXClientError.cannotCreateRequest
    
    @inlinable
    func waitFor(block: @escaping (XCTestExpectation)->Void) {
        let expect = expectation(description: "Waiting")
        DispatchQueue.global().async {
            block(expect)
        }
        wait(for: [ expect ], timeout: 1)
    }


    override func setUpWithError() throws {
        api = IDXClientAPIv1Mock(configuration: context.configuration)
        client = IDXClient(context: context, api: api)
        client.delegate = delegate
        
        remediationOption = Remediation(
            client: client,
            name: "cancel",
            method: "GET",
            href: URL(string: "some://url")!,
            accepts: "application/json",
            form: Remediation.Form(fields: [
                Remediation.Form.Field(name: "foo",
                                                 visible: false,
                                                 mutable: true,
                                                 required: false,
                                                 secret: false)
            ])!,
            refresh: nil,
            relatesTo: nil,
            capabilities: [])
        token = Token(accessToken: "access",
                                refreshToken: "refresh",
                                expiresIn: 10,
                                idToken: "id",
                                scope: "scope",
                                tokenType: "type",
                                configuration: context.configuration)
        response = Response(client: client,
                                      expiresAt: Date(),
                                      intent: .login,
                                      authenticators: .init(authenticators: nil),
                                      remediations: .init(remediations: [remediationOption]),
                                      successRemediationOption: remediationOption,
                                      messages: .init(messages: nil),
                                      app: nil,
                                      user: nil)
        
        redirectUrl = URL(string: "com.scheme://path")
    }

    override func tearDown() {
        delegate.reset()
        api.reset()
    }

    func testResumeError() {
        api.expect(function: "resume(completion:)", arguments: ["error": error])
        waitFor { expectation in
            self.client.resume { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }
    
    func testCancelError() {
        api.expect(function: "proceed(remediation:completion:)", arguments: ["error": error])
        waitFor { expectation in
            self.response.cancel { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }
    
    func testProceedError() {
        api.expect(function: "proceed(remediation:completion:)", arguments: ["error": error])
        waitFor { expectation in
            self.client.proceed(remediation: self.remediationOption) { result in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }
    
    func testExchangeRedirectCodeError() {
        api.expect(function: "exchangeCode(redirect:completion:)", arguments: ["error": error])
        waitFor { expectation in
            self.client.exchangeCode(redirect: self.redirectUrl) { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }

    func testExchangeCodeError() {
        api.expect(function: "exchangeCode(using:completion:)", arguments: ["error": error])
        waitFor { expectation in
            self.client.exchangeCode(using: self.remediationOption) { result in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .error)
    }
    
    func testToken() {
        // exchangeCode()
        api.expect(function: "exchangeCode(using:completion:)", arguments: ["response": token as Any])
        waitFor { expectation in
            self.client.exchangeCode(using: self.remediationOption) { result in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .token)
        XCTAssertEqual(delegate.calls.first?.token, token)
    }
    
    func testExchangeCodeRedirectUrlFromClient() {
        api.expect(function: "exchangeCode(redirect:completion:)", arguments: ["response": token as Any])
        waitFor { expectation in
            self.client.exchangeCode(redirect: self.redirectUrl) { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .token)
        XCTAssertEqual(delegate.calls.first?.token, token)
    }

    func testExchangeCodeFromResponse() {
        api.expect(function: "exchangeCode(using:completion:)", arguments: ["response": token as Any])
        waitFor { expectation in
            self.response.exchangeCode { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .token)
        XCTAssertEqual(delegate.calls.first?.token, token)
    }

    func testResume() {
        // introspect()
        api.expect(function: "resume(completion:)", arguments: ["response": response as Any])
        waitFor { expectation in
            self.client.resume() { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
        XCTAssertEqual(delegate.calls.first?.response, response)
    }
    
    func testCancel() {
        api.expect(function: "proceed(remediation:completion:)", arguments: ["response": response as Any])
        waitFor { expectation in
            self.response.cancel { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
        XCTAssertEqual(delegate.calls.first?.response, response)
    }
    
    func testProceed() {
        api.expect(function: "proceed(remediation:completion:)", arguments: ["response": response as Any])
        waitFor { expectation in
            self.remediationOption.proceed { (_, _) in
                expectation.fulfill()
            }
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
        XCTAssertEqual(delegate.calls.first?.response, response)
    }
    
    func testResumeWithoutCompletionBlock() {
        api.expect(function: "resume(completion:)", arguments: ["response": response as Any])
        waitFor { expectation in
            self.client.resume { response, error in }
            expectation.fulfill()
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
        XCTAssertEqual(delegate.calls.first?.response, response)
    }
    
    func testExchangeCodeRedirectWithoutCompletionBlock() {
        // exchangeCode()
        api.expect(function: "exchangeCode(redirect:completion:)", arguments: ["response": token as Any])
        waitFor { expectation in
            self.client.exchangeCode(redirect: self.redirectUrl) { token, error in }
            expectation.fulfill()
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .token)
        XCTAssertEqual(delegate.calls.first?.token, token)
    }
    
    func testExchangeCodeWithoutCompletionBlock() {
        api.expect(function: "exchangeCode(using:completion:)", arguments: ["response": token as Any])
        waitFor { expectation in
            self.response.exchangeCode { token, error in }
            expectation.fulfill()
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .token)
        XCTAssertEqual(delegate.calls.first?.token, token)
    }
    
    func testCancelWithoutCompletionBlock() {
        api.expect(function: "proceed(remediation:completion:)", arguments: ["response": response as Any])
        waitFor { expectation in
            self.response.cancel { response, error in }
            expectation.fulfill()
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
        XCTAssertEqual(delegate.calls.first?.response, response)
    }
    
    func testProceedWithoutCompletionBlock() {
        api.expect(function: "proceed(remediation:completion:)", arguments: ["response": response as Any])
        waitFor { expectation in
            self.remediationOption.proceed { response, error in }
            expectation.fulfill()
        }
        XCTAssertEqual(delegate.calls.count, 1)
        XCTAssertEqual(delegate.calls.first?.type, .response)
        XCTAssertEqual(delegate.calls.first?.response, response)
    }
}
