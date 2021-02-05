//
//  IDXClientTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import XCTest
@testable import OktaIdx

class IDXClientTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "issuer",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    var client: IDXClient!
    var api: IDXClientAPIv1Mock!
    
    override func setUpWithError() throws {
        api = IDXClientAPIv1Mock(configuration: configuration)
        client = IDXClient(configuration: configuration,
                           context: nil,
                           api: api,
                           queue: DispatchQueue.main)
    }

    func testConstructors() {
        var idx = IDXClient(configuration: configuration)
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.configuration, configuration)
        XCTAssertNil(idx.context)
        
        let context = IDXClient.Context(interactionHandle: "foo", codeVerifier: "bar")
        idx = IDXClient(configuration: configuration, context: context)
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.configuration, configuration)
        XCTAssertEqual(idx.context, context)
    }
    
    func testApiDelegation() {
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
                                          currentAuthenticatorEnrollment: nil,
                                          remediation: nil,
                                          cancel: remedationOption,
                                          success: remedationOption,
                                          messages: nil,
                                          app: nil,
                                          user: nil)

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
        XCTAssertEqual(call?.function, "interact(completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()

        // introspect()
        expect = expectation(description: "introspect")
        client.introspect("foo") { (_, _) in
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
        client.exchangeCode(using: response) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Response, response)
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
        response.exchangeCode() { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Response, response)
        api.reset()
    }
}
