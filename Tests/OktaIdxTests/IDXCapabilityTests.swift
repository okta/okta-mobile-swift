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
    let clientMock = IDXClientAPIMock(context: .init(configuration: .init(issuer: "https://example.com",
                                                                          clientId: "Bar",
                                                                          clientSecret: nil,
                                                                          scopes: ["scope"],
                                                                          redirectUri: "redirect:/"),
                                                     state: "state",
                                                     interactionHandle: "handle",
                                                     codeVerifier: "verifier"))
    var remediation: IDXClient.Remediation!
    var response: IDXClient.Response!

    override func setUpWithError() throws {
        let fields = try XCTUnwrap(IDXClient.Remediation.Form(fields: []))
        remediation = IDXClient.Remediation(client: clientMock,
                                            name: "remediation",
                                            method: "POST",
                                            href: URL(string: "https://example.com/idp/path")!,
                                            accepts: nil,
                                            form: fields,
                                            refresh: nil,
                                            relatesTo: nil,
                                            capabilities: [])
        response = try IDXClient.Response.response(client: clientMock,
                                                   fileName: "introspect-response")
    }

    func testProfileCapability() throws {
        let capability = Capability.Profile(profile: ["email":"email@okta.com"])
        XCTAssertEqual(capability["email"], "email@okta.com")
    }

    func testRecoverableCapability() throws {
        clientMock.expect(function: "proceed(remediation:completion:)",
                          arguments: ["response": response as Any])
        
        let capability = Capability.Recoverable(client: clientMock, remediation: remediation)
        capability.recover { result in
            guard case Result.success(_) = result else { XCTFail()
                return
            }
        }
        
        XCTAssertEqual(clientMock.recordedCalls.count, 1)
    }

    func testSendableCapability() throws {
        clientMock.expect(function: "proceed(remediation:completion:)",
                          arguments: ["response": response as Any])
        
        let capability = Capability.Sendable(client: clientMock, remediation: remediation)
        capability.send { result in
            guard case Result.success(_) = result else { XCTFail()
                return
            }
        }
        
        XCTAssertEqual(clientMock.recordedCalls.count, 1)
    }

    func testResendableCapability() throws {
        clientMock.expect(function: "proceed(remediation:completion:)",
                          arguments: ["response": response as Any])
        
        let capability = Capability.Resendable(client: clientMock, remediation: remediation)
        capability.resend { result in
            guard case Result.success(_) = result else { XCTFail()
                return
            }
        }
        
        XCTAssertEqual(clientMock.recordedCalls.count, 1)
    }
}
