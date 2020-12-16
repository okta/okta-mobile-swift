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
                           api: api)
    }

    func testApiDelegation() {
        XCTAssertEqual(api.recordedCalls.count, 0)
        
        let credentials = IDXClient.Credentials(passcode: "pass", answer: "answer")
        let authenticator = IDXClient.Authenticator(id: "id", methodType: "method", phoneNumber: "phoneNumber")
        let remedationOption = IDXClient.Remediation.Option(client: api,
                                                            rel: ["foo"],
                                                            name: "name",
                                                            method: "GET",
                                                            href: URL(string: "some://url")!,
                                                            accepts: "application/json",
                                                            form: [])

        var expect: XCTestExpectation!
        var call: IDXClientAPIv1Mock.RecordedCall?
        var called = false
        
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
        client.introspect("handle") { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "introspect(_:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["interactionHandle"] as! String, "handle")
        api.reset()

        // identify()
        expect = expectation(description: "identify")
        called = false
        client.identify(identifier: "foo", credentials: credentials, rememberMe: false) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "identify(identifier:credentials:rememberMe:completion:)")
        XCTAssertEqual(call?.arguments?.count, 3)
        XCTAssertEqual(call?.arguments?["identifier"] as! String, "foo")
        XCTAssertEqual(call?.arguments?["credentials"] as! IDXClient.Credentials, credentials)
        XCTAssertEqual(call?.arguments?["rememberMe"] as! Bool, false)
        api.reset()

        // enroll()
        expect = expectation(description: "enroll")
        called = false
        client.enroll(authenticator: authenticator) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "enroll(authenticator:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["authenticator"] as! IDXClient.Authenticator, authenticator)
        api.reset()

        // challenge()
        expect = expectation(description: "challenge")
        called = false
        client.challenge(authenticator: authenticator) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "challenge(authenticator:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["authenticator"] as! IDXClient.Authenticator, authenticator)
        api.reset()

        // answerChallenge()
        expect = expectation(description: "answerChallenge")
        called = false
        client.answerChallenge(credentials: credentials) { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "answerChallenge(credentials:completion:)")
        XCTAssertEqual(call?.arguments?.count, 1)
        XCTAssertEqual(call?.arguments?["credentials"] as! IDXClient.Credentials, credentials)
        api.reset()

        // cancel()
        expect = expectation(description: "cancel")
        client.cancel { (_) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "cancel(completion:)")
        XCTAssertNil(call?.arguments)
        api.reset()

        // token()
        expect = expectation(description: "token")
        client.token(url: "url", grantType: "grant", interactionCode: "code") { (_, _) in
            called = true
            expect.fulfill()
        }
        wait(for: [ expect ], timeout: 1)
        XCTAssertTrue(called)
        call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "token(url:grantType:interactionCode:completion:)")
        XCTAssertEqual(call?.arguments?.count, 3)
        XCTAssertEqual(call?.arguments?["url"] as! String, "url")
        XCTAssertEqual(call?.arguments?["grantType"] as! String, "grant")
        XCTAssertEqual(call?.arguments?["interactionCode"] as! String, "code")
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
        
        // Option.proceed()
        expect = expectation(description: "Option.proceed")
        remedationOption.proceed(with: ["foo": "bar" as! AnyObject]) { (_, _) in
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
    }
}
