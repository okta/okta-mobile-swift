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

class IDXClientTests: XCTestCase {
    let context = IDXClient.Context(configuration: .init(issuer: "issuer",
                                                         clientId: "clientId",
                                                         clientSecret: "clientSecret",
                                                         scopes: ["all"],
                                                         redirectUri: "redirect:/uri"),
                                    state: "state",
                                    interactionHandle: "foo",
                                    codeVerifier: "bar")
    var client: IDXClient!
    var api: IDXClientAPIv1Mock!
    
    override func setUpWithError() throws {
        api = IDXClientAPIv1Mock(configuration: context.configuration)
        client = IDXClient(context: context, api: api)
    }

    func testConstructors() {
        let idx = IDXClient(context: context, api: api)
        
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.context, context)
    }
    
    func testApiDelegation() throws {
        XCTAssertEqual(api.recordedCalls.count, 0)
        
        let remedationOption = try XCTUnwrap(IDXClient.Remediation(
                                                client: client,
                                                name: "cancel",
                                                method: "GET",
                                                href: URL(string: "some://url")!,
                                                accepts: "application/json",
                                                form: IDXClient.Remediation.Form(fields: [
                                                    IDXClient.Remediation.Form.Field(name: "foo",
                                                                                     visible: false,
                                                                                     mutable: true,
                                                                                     required: false,
                                                                                     secret: false)
                                                ])!,
                                                refresh: nil,
                                                relatesTo: nil,
                                                capabilities: []))
        let response = IDXClient.Response(client: client,
                                          expiresAt: Date(),
                                          intent: .login,
                                          authenticators: .init(authenticators: nil),
                                          remediations: .init(remediations: [remedationOption]),
                                          successRemediationOption: remedationOption,
                                          messages: .init(messages: nil),
                                          app: nil,
                                          user: nil)
        
        let redirectUrl = try XCTUnwrap(URL(string: "com.scheme://path"))

        var expect: XCTestExpectation!
        var call: IDXClientAPIv1Mock.RecordedCall?
        var called = false
        
        // start()
        expect = expectation(description: "start")
        IDXClient.start(with: api, state: "state") { result in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "start(state:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["state"] as! String, "state")
        api.reset()

        // resume()
        expect = expectation(description: "resume")
        client.resume { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "resume(completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()

        // proceed()
        expect = expectation(description: "proceed")
        client.proceed(remediation: remedationOption) { result in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "proceed(remediation:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["remediation"] as! IDXClient.Remediation, remedationOption)
        api.reset()
        
        // exchangeCode()
        expect = expectation(description: "exchangeCode")
        client.exchangeCode(using: remedationOption) { result in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Remediation, remedationOption)
        api.reset()
        
        // exchangeCodeRedirect()
        expect = expectation(description: "exchangeCode(redirect:completion:)")
        client.exchangeCode(redirect: redirectUrl) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(redirect:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["redirect"] as! URL, redirectUrl)
        api.reset()
        
        // revoke()
        expect = expectation(description: "revoke(token:type:completion:)")
        IDXClient.Token.revoke(token: "token", type: .refreshToken, api: api) { result in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "revoke(token:type:completion:)")
        XCTAssertEqual(call?.arguments?.count, 2)
        XCTAssertEqual(call?.arguments?["token"] as! String, "token")
        XCTAssertEqual(call?.arguments?["type"] as! String, "refresh_token")
        api.reset()

        // redirectResult()
        let url = try XCTUnwrap(URL(string: "redirect://uri"))
        let result = client.redirectResult(for: url)
        XCTAssertEqual(result, .invalidContext)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "redirectResult(for:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["url"] as! URL, url)
        api.reset()

        // Option.proceed()
        expect = expectation(description: "Option.proceed")
        remedationOption.proceed { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "proceed(remediation:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["remediation"] as? IDXClient.Remediation, remedationOption)
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
        XCTAssertEqual(call?.function, "proceed(remediation:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["remediation"] as! IDXClient.Remediation, remedationOption)
        api.reset()

        // Response.exchangeCode()
        expect = expectation(description: "Response.exchangeCode")
        response.exchangeCode { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Remediation, remedationOption)
        api.reset()
    }
}
