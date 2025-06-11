//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import XCTest
@testable import OktaIdx

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class IDXCapabilityTests: XCTestCase {
    var client: OAuth2Client!
    var redirectUri: URL!
    let urlSession = URLSessionMock()
    var flowMock: InteractionCodeFlowMock!
    var remediation: Remediation!
    var responseData: Data!
    var response: Response!

    override func setUpWithError() throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))

        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              session: urlSession)

        let context = InteractionCodeFlow.Context(interactionHandle: "handle",
                                                  recoveryToken: nil,
                                                  state: "state",
                                                  pkce: nil,
                                                  acrValues: nil,
                                                  maxAge: nil,
                                                  nonce: nil,
                                                  additionalParameters: nil)
        flowMock = InteractionCodeFlowMock(context: context, client: client, redirectUri: redirectUri)

        let fields = try XCTUnwrap(Remediation.Form(fields: []))
        remediation = Remediation(flow: flowMock,
                                  name: "remediation",
                                  method: .post,
                                  href: URL(string: "https://example.com/idp/path")!,
                                  accepts: .ionJson,
                                  form: fields,
                                  refresh: nil,
                                  relatesTo: nil,
                                  capabilities: [])
        responseData = try data(from: .module,
                                for: "introspect-response")
        response = try Response.response(flow: flowMock,
                                         data: data(from: .module,
                                                    for: "introspect-response"))
    }

    func testProfileCapability() throws {
        let capability = ProfileCapability(profile: ["email":"email@okta.com"])
        XCTAssertEqual(capability["email"], "email@okta.com")
    }

    func testRecoverCapability() async throws {
        await flowMock.expect(function: "resume(with:)",
                        arguments: ["object": response as Any])
        urlSession.expect("https://example.com/idp/path", data: responseData)
        
        let capability = RecoverCapability(remediation: remediation)
        _ = try await capability.recover()

        let calls = await flowMock.recordedCalls
        XCTAssertEqual(calls.count, 1)
    }

    func testSendCapability() async throws {
        await flowMock.expect(function: "resume(with:)",
                              arguments: ["object": response as Any])
        urlSession.expect("https://example.com/idp/path", data: responseData)

        let capability = SendCapability(remediation: remediation)
        _ = try await capability.send()

        let calls = await flowMock.recordedCalls
        XCTAssertEqual(calls.count, 1)
    }
    
    func testResendCapability() async throws {
        await flowMock.expect(function: "resume(with:)",
                              arguments: ["object": response as Any])
        urlSession.expect("https://example.com/idp/path", data: responseData)
        
        let capability = ResendCapability(remediation: remediation)
        _ = try await capability.resend()

        let calls = await flowMock.recordedCalls
        XCTAssertEqual(calls.count, 1)
    }
    
    func testDuoSignatureData() async throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        
        client = OAuth2Client(issuerURL: issuer,
                              clientId: "clientId",
                              scope: "openid profile",
                              session: urlSession)

        flowMock = InteractionCodeFlowMock(client: client, redirectUri: redirectUri)
        
        let signatureField = Remediation.Form.Field(name: "signatureData", visible: false, mutable: true, required: false, secret: false)
        let duo = DuoCapability(host: "", signedToken: "", script: "")
        let credentials = Remediation.Form.Field(name: "credentials",
                                                 label: "credentials",
                                                 visible: true,
                                                 mutable: true,
                                                 required: false,
                                                 secret: false,
                                                 form: .init(fields: [signatureField]))
        let form = try XCTUnwrap(Remediation.Form(fields: [ credentials ]))
        let authenticator =  Authenticator(flow: flowMock,
                                           v1JsonPaths: [], state: .authenticating,
                                           id: "duo",
                                           displayName: "",
                                           type: .app,
                                           key: "app",
                                           methods: [["type":"duo"]],
                                           capabilities: [duo])
        remediation = Remediation(flow: flowMock,
                                  name: "remediation",
                                  method: .post,
                                  href: URL(string: "https://example.com/idp/path")!,
                                  accepts: .ionJson,
                                  form: form,
                                  refresh: nil,
                                  relatesTo: nil,
                                  capabilities: [],
                                  authenticators: [authenticator])

        responseData = try data(from: .module,
                                for: "introspect-response")
        duo.signatureData = "signature"
        duo.willProceed(to: remediation)
        XCTAssertEqual(signatureField.value as? String, "signature")
    }
    
    func testPollCapability() async throws {
        responseData = try data(from: .module, for: "06-idx-challenge", in: "MFA-SOP")
        response = try Response.response(flow: flowMock, data: responseData)
        remediation = try XCTUnwrap(response.remediations[.challengeAuthenticator])

        let authenticator = try XCTUnwrap(response.authenticators.current)
        XCTAssertEqual(authenticator.type, .email)
        
        let pollable = try XCTUnwrap(authenticator.pollable)
        
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
        urlSession.expect("https://example.com/idp/idx/challenge/poll",
                          data: nil,
                          statusCode: 400,
                          error: error)
        await flowMock.expect(function: "resume(with:)",
                              arguments: ["error": error])

        let successData = try data(from: .module,
                                    for: "success-response")
        let successResponse = try Response.response(flow: flowMock, data: successData)
        urlSession.expect("https://example.com/idp/idx/challenge/poll", data: successData)
        await flowMock.expect(function: "resume(with:)",
                              arguments: ["object": successResponse])

        let response = try await pollable.proceed()
        XCTAssertTrue(response.isLoginSuccessful)

        let flowCalls = await flowMock.recordedCalls
        XCTAssertEqual(flowCalls.count, 0)

        XCTAssertEqual(urlSession.requests.count, 2)
    }
}
