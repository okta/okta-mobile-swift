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

    func testInteractSuccess() throws {
        XCTAssertEqual(api.recordedCalls.count, 0)
        
        var completion: XCTestExpectation!
        var call: IDXClientAPIv1Mock.RecordedCall?
        var called = false
        
        // interact()
        completion = expectation(description: "interact")
        api.expect(function: "interact(completion:)", arguments: ["handle": "ABCeasyas123"])
        let _ = client.interact().sink { (value) in
            completion.fulfill()
        } receiveValue: { value in
            called = true
            XCTAssertEqual(value, "ABCeasyas123")
        }
        wait(for: [completion], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "interact(completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()
    }
}
