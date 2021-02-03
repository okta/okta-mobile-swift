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
    var remedationOption: IDXClient.Remediation.Option!
    var response: IDXClient.Response!
    var context: IDXClient.Context!
    var token: IDXClient.Token!

    override func setUpWithError() throws {
        guard #available(iOSApplicationExtension 13.0, *) else {
            throw XCTSkip("Unable to test Combine promise/futures on this platform")
        }

        api = IDXClientAPIv1Mock(configuration: configuration)
        client = IDXClient(configuration: configuration,
                           context: nil,
                           api: api,
                           queue: DispatchQueue.global())
        remedationOption = IDXClient.Remediation.Option(client: api,
                                                        rel: ["foo"],
                                                        name: "name",
                                                        method: "GET",
                                                        href: URL(string: "some://url")!,
                                                        accepts: "application/json",
                                                        form: [],
                                                        relatesTo: nil,
                                                        refresh: nil)
        context = IDXClient.Context(interactionHandle: "interactionHandle",
                                    codeVerifier: "verifier")
        response = IDXClient.Response(client: api,
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
        token = IDXClient.Token(accessToken: "accessToken", refreshToken: nil, expiresIn: 800, idToken: nil, scope: "", tokenType: "bear")
    }

    func testProceed() throws {
        var called = false
        let completion = expectation(description: "proceed")
        api.expect(function: "proceed(remediation:data:completion:)", arguments: ["response": response as Any])
        let _ = remedationOption.proceed().sink { (value) in
            completion.fulfill()
        } receiveValue: { response in
            called = true
            XCTAssertEqual(response, self.response)
        }
        wait(for: [completion], timeout: 1)
        XCTAssertTrue(called)
        let call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "proceed(remediation:data:completion:)")
        XCTAssertEqual(call?.arguments!["remediation"] as? IDXClient.Remediation.Option, remedationOption)
    }

    func testExchangeCode() throws {
        var called = false
        let completion = expectation(description: "exchangeCode")
        api.expect(function: "exchangeCode(using:completion:)", arguments: ["token": token as Any])
        let _ = response.exchangeCode().sink { (value) in
            completion.fulfill()
        } receiveValue: { response in
            called = true
            XCTAssertEqual(response, self.token)
        }
        wait(for: [completion], timeout: 1)
        XCTAssertTrue(called)
        let call = api.recordedCalls.last
        XCTAssertEqual(call?.function, "exchangeCode(using:completion:)")
        XCTAssertEqual(call?.arguments!["using"] as? IDXClient.Remediation.Option, remedationOption)
    }

    func testStart() throws {
        api.expect(function: "interact(completion:)", arguments: ["context": context as Any])
        api.expect(function: "introspect(_:completion:)", arguments: ["response": response as Any])

        var called = false
        let completion = expectation(description: "start")
        let _ = client.start().sink { value in
            completion.fulfill()
        } receiveValue: { value in
            called = true
            XCTAssertNotNil(value)
            XCTAssertEqual(value, self.response)
        }
        wait(for: [completion], timeout: 2)
        XCTAssertTrue(called)
    }
}
