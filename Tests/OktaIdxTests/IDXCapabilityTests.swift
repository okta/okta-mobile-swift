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

        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        let context = try InteractionCodeFlow.Context(interactionHandle: "handle", state: "state")
        
        flowMock = InteractionCodeFlowMock(context: context, client: client, redirectUri: redirectUri)

        let fields = try XCTUnwrap(Remediation.Form(fields: []))
        remediation = Remediation(flow: flowMock,
                                  name: "remediation",
                                  method: "POST",
                                  href: URL(string: "https://example.com/idp/path")!,
                                  accepts: "application/ion+json; okta-version=1.0.0",
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
        let capability = Capability.Profile(profile: ["email":"email@okta.com"])
        XCTAssertEqual(capability["email"], "email@okta.com")
    }

    func testRecoverableCapability() throws {
        flowMock.expect(function: "send(response:completion:)",
                        arguments: ["response": response as Any])
        urlSession.expect("https://example.com/idp/path", data: responseData)
        
        let wait = expectation(description: "Recover")
        let capability = Capability.Recoverable(remediation: remediation)
        capability.recover { result in
            defer { wait.fulfill() }
            guard case Result.success(_) = result else { XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(flowMock.recordedCalls.count, 1)
    }

    func testSendableCapability() throws {
        flowMock.expect(function: "send(response:completion:)",
                        arguments: ["response": response as Any])
        urlSession.expect("https://example.com/idp/path", data: responseData)

        let wait = expectation(description: "Recover")
        let capability = Capability.Sendable(remediation: remediation)
        capability.send { result in
            defer { wait.fulfill() }
            guard case Result.success(_) = result else { XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(flowMock.recordedCalls.count, 1)
    }
    
    func testResendableCapability() throws {
        flowMock.expect(function: "send(response:completion:)",
                        arguments: ["response": response as Any])
        urlSession.expect("https://example.com/idp/path", data: responseData)
        
        let wait = expectation(description: "Recover")
        let capability = Capability.Resendable(remediation: remediation)
        capability.resend { result in
            defer { wait.fulfill() }
            guard case Result.success(_) = result else { XCTFail()
                return
            }
        }
        waitForExpectations(timeout: 1.0)
        
        XCTAssertEqual(flowMock.recordedCalls.count, 1)
    }
    
    func testDuoSignatureData() throws {
        let issuer = try XCTUnwrap(URL(string: "https://example.com/oauth2/default"))
        redirectUri = try XCTUnwrap(URL(string: "redirect:/uri"))
        
        client = OAuth2Client(baseURL: issuer,
                              clientId: "clientId",
                              scopes: "openid profile",
                              session: urlSession)
        
        let context = try InteractionCodeFlow.Context(interactionHandle: "handle", state: "state")
        
        flowMock = InteractionCodeFlowMock(context: context, client: client, redirectUri: redirectUri)
        
        let signatureField = Remediation.Form.Field(name: "signatureData", visible: false, mutable: true, required: false, secret: false)
        let duo = Capability.Duo(host: "", signedToken: "", script: "")
        let credentials = Remediation.Form.Field(name: "credentials",
                                                 label: "credentials",
                                                 visible: true,
                                                 mutable: true,
                                                 required: false,
                                                 secret: false,
                                                 form: .init(fields: [signatureField]))
        let form = try XCTUnwrap(Remediation.Form(fields: [ credentials ]))
        remediation = Remediation(flow: flowMock,
                                  name: "remediation",
                                  method: "POST",
                                  href: URL(string: "https://example.com/idp/path")!,
                                  accepts: "application/ion+json; okta-version=1.0.0",
                                  form: form,
                                  refresh: nil,
                                  relatesTo: nil,
                                  capabilities: [])
        let authenticator =  Authenticator(flow: flowMock,
                                           v1JsonPaths: [], state: .authenticating,
                                           id: "duo",
                                           displayName: "",
                                           type: "app",
                                           key: "app",
                                           methods: [["type":"duo"]],
                                           capabilities: [duo])
        
        remediation.authenticators = .init(authenticators: [authenticator])
        responseData = try data(from: .module,
                                for: "introspect-response")
        duo.signatureData = "signature"
        duo.willProceed(to: remediation)
        XCTAssertEqual(signatureField.value?.stringValue,"signature")
    }
}
