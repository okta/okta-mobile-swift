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
                           api: api,
                           queue: DispatchQueue.main)
    }

    func testConstructors() {
        var idx = IDXClient(configuration: configuration)
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.configuration, configuration)
        
        idx = IDXClient(issuer: "https://example.com", clientId: "bar", scopes: ["baz"], redirectUri: "boo")
        XCTAssertNotNil(idx)
        XCTAssertEqual(idx.configuration.issuer, "https://example.com")
        XCTAssertEqual(idx.configuration.clientId, "bar")
        XCTAssertEqual(idx.configuration.scopes, ["baz"])
        XCTAssertEqual(idx.configuration.redirectUri, "boo")
    }
    
    func testApiDelegation() {
        XCTAssertEqual(api.recordedCalls.count, 0)
        
        let remedationOption = IDXClient.Remediation.Option(client: api,
                                                            rel: ["foo"],
                                                            name: "name",
                                                            method: "GET",
                                                            href: URL(string: "some://url")!,
                                                            accepts: "application/json",
                                                            form: [])
        let response = IDXClient.Response(client: api,
                                          stateHandle: "handle",
                                          version: "1",
                                          expiresAt: Date(),
                                          intent: "Login",
                                          remediation: nil,
                                          cancel: remedationOption,
                                          success: remedationOption,
                                          messages: nil)

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
        client.exchangeCode(using: remedationOption) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(using:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Remediation.Option, remedationOption)
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
        XCTAssertEqual(call?.arguments?["remediation"] as! IDXClient.Remediation.Option, remedationOption)
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
        XCTAssertEqual(call?.arguments?["using"] as! IDXClient.Remediation.Option, remedationOption)
        api.reset()
    }
}
