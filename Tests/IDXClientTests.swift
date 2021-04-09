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

class IDXClientTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "issuer",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    let context = IDXClient.Context(state: "state", interactionHandle: "foo", codeVerifier: "bar")
    var client: IDXClient!
    var api: IDXClientAPIv1Mock!
    
    var redirectClient: IDXClient!
    
    override func setUpWithError() throws {
        api = IDXClientAPIv1Mock(configuration: configuration)
        client = IDXClient(configuration: configuration,
                           context: nil,
                           api: api,
                           queue: DispatchQueue.main)
        
        redirectClient = IDXClient(
            configuration: configuration,
            context: context,
            api: IDXClient.APIVersion1(with: configuration, session: URLSessionMock()),
            queue: .main)
    }

    func testConstructors() {
        var idx = IDXClient(configuration: configuration)
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.configuration, configuration)
        XCTAssertNil(idx.context)
        
        idx = IDXClient(configuration: configuration, context: context)
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.configuration, configuration)
        XCTAssertEqual(idx.context, context)
    }
    
    func testApiDelegation() throws {
        XCTAssertEqual(api.recordedCalls.count, 0)
        
        let remedationOption = IDXClient.Remediation.Option(api: api,
                                                            rel: ["foo"],
                                                            name: "name",
                                                            method: "GET",
                                                            href: URL(string: "some://url")!,
                                                            accepts: "application/json",
                                                            form: [
                                                                IDXClient.Remediation.FormValue(name: "foo",
                                                                                                visible: false,
                                                                                                mutable: true,
                                                                                                required: false,
                                                                                                secret: false)
                                                            ],
                                                            relatesTo: nil,
                                                            refresh: nil)
        let response = IDXClient.Response(api: api,
                                          stateHandle: "handle",
                                          version: "1",
                                          expiresAt: Date(),
                                          intent: "Login",
                                          authenticators: nil,
                                          authenticatorEnrollments: nil,
                                          currentAuthenticator: nil,
                                          currentAuthenticatorEnrollment: nil,
                                          remediation: nil,
                                          cancel: remedationOption,
                                          success: remedationOption,
                                          messages: nil,
                                          app: nil,
                                          user: nil)
        
        let redirectUrl = try XCTUnwrap(URL(string: "com.scheme://path"))

        var expect: XCTestExpectation!
        var call: IDXClientAPIv1Mock.RecordedCall?
        var called = false
        
        // canCancel
        XCTAssertFalse(client.canCancel)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "canCancel")
        XCTAssertNil(call?.arguments)
        api.reset()

        // cancel()
        expect = expectation(description: "cancel")
        client.cancel { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "cancel(completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()

        // interact()
        expect = expectation(description: "interact")
        client.interact { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "interact(state:completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()

        // introspect()
        expect = expectation(description: "introspect")
        client.introspect(context) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "introspect(_:completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()

        // proceed()
        expect = expectation(description: "proceed")
        client.proceed(remediation: remedationOption, data: ["Foo": "Bar"]) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "proceed(remediation:data:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["remediation"] as! IDXClient.Remediation.Option, remedationOption)
        api.reset()
        
        // exchangeCode()
        expect = expectation(description: "exchangeCode")
        client.exchangeCode(with: context, using: response) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(with:using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["with"] as! IDXClient.Context, context)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Response, response)
        api.reset()
        
        // exchangeCodeRedirect()
        expect = expectation(description: "exchangeCode(with:redirect:completion:)")
        client.exchangeCode(with: context, redirect: redirectUrl) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(with:redirect:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["with"] as! IDXClient.Context, context)
        XCTAssertEqual(call?.arguments?["redirect"] as! URL, redirectUrl)
        api.reset()
        
        // Option.proceed()
        expect = expectation(description: "Option.proceed")
        remedationOption.proceed(with: ["foo": "bar" as AnyObject]) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "proceed(remediation:data:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["remediation"] as? IDXClient.Remediation.Option, remedationOption)
        api.reset()

        // Response.cancel()
        expect = expectation(description: "Response.cancel")
        response.cancel() {_,_ in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "proceed(remediation:data:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["remediation"] as! IDXClient.Remediation.Option, remedationOption)
        api.reset()

        // Response.exchangeCode()
        expect = expectation(description: "Response.exchangeCode")
        response.exchangeCode(with: context) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(with:using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["with"] as! IDXClient.Context, context)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Response, response)
        api.reset()
    }
    
    func testRedirectResultWithInvalidContext() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:/uri"))
        
        let client = IDXClient(
            configuration: configuration,
            context: nil,
            api: IDXClient.APIVersion1(with: configuration, session: URLSessionMock()),
            queue: .main)
        
        XCTAssertEqual(client.redirectResult(with: nil, redirect: redirectUrl), .invalidContext)
    }
    
    func testRedirectResultAuthenticated() throws {
        let redirectUrl = try XCTUnwrap(URL(string: """
                redirect:///uri?\
                interaction_code=qwe4xJasF897EbEKL0LLbNUI-QwXZa8YOkY8QkWUlpXxU&\
                state=state#_=_
                """))
        
        XCTAssertEqual(redirectClient.redirectResult(redirect: redirectUrl), .authenticated)
    }
    
    func testRedirectResultWithInvalidUrl() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect///uri"))
        
        XCTAssertEqual(redirectClient.redirectResult(redirect: redirectUrl), .invalidRedirectUrl)
    }
    
    func testRedirectResultWithInvalidScheme() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect.com:///uri"))
        
        XCTAssertEqual(redirectClient.redirectResult(redirect: redirectUrl), .invalidRedirectUrl)
    }
    
    func testRedirectResultWithInvalidState() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state1"))
        
        XCTAssertEqual(redirectClient.redirectResult(redirect: redirectUrl), .invalidContext)
    }

    func testRedirectResultWithRemediationError() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state&error=interaction_required"))
        
        XCTAssertEqual(redirectClient.redirectResult(redirect: redirectUrl), .remediationRequired)
    }
    
    func testRedirectResultWithEmptyResponse() throws {
        let redirectUrl = try XCTUnwrap(URL(string: "redirect:///uri?state=state"))
        
        XCTAssertEqual(redirectClient.redirectResult(redirect: redirectUrl), .invalidContext)
    }
}
