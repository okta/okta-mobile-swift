//
//  IDXClientCombineTests.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-14.
//

import XCTest
@testable import OktaIdx

@available(iOS 13.0, *)
class IDXClientCombineTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "issuer",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    var client: IDXClient!
    var api: IDXClientAPIv1Mock!
    
    override func setUpWithError() throws {
        guard #available(iOSApplicationExtension 13.0, *) else {
            throw XCTSkip("Unable to test Combine promise/futures on this platform")
        }

        api = IDXClientAPIv1Mock(configuration: configuration)
        client = IDXClient(configuration: configuration,
                           api: api)
    }

    func testInteract() throws {
        var called = false
        let completion = expectation(description: "interact")
        api.expect(function: "interact(completion:)", arguments: ["handle": "ABCeasyas123"])
        let _ = client.interact().sink { (value) in
            completion.fulfill()
        } receiveValue: { value in
            called = true
            XCTAssertEqual(value, "ABCeasyas123")
        }
        wait(for: [completion], timeout: 1)
        XCTAssertTrue(called)
        let call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "interact(completion:)")
        XCTAssertNil(call?.arguments)
    }

    func testIntrospect() throws {
        var called = false
        let completion = expectation(description: "interact")
        api.expect(function: "introspect(_:completion:)", arguments: ["interactionHandle": "handle"])
        let _ = client.introspect("ABCeasyas123").sink { (value) in
            completion.fulfill()
        } receiveValue: { value in
            called = true
            XCTAssertEqual(value.stateHandle, "handle")
        }
        wait(for: [completion], timeout: 1)
        XCTAssertTrue(called)
        let call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "introspect(_:completion:)")
        XCTAssertEqual(call?.arguments!["interactionHandle"] as? String, "ABCeasyas123")
    }
}
