//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

class IDXAuthenticatorCollectionTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "https://foo.oktapreview.com/oauth2/default",
                                                clientId: "clientId",
                                                clientSecret: "clientSecret",
                                                scopes: ["all"],
                                                redirectUri: "redirect:/uri")
    var context: IDXClient.Context!
    var session: URLSessionMock!
    var api: IDXClient.APIVersion1!
    var client: IDXClientAPIMock!
    
    override func setUpWithError() throws {
        session = URLSessionMock()
        context = IDXClient.Context(configuration: configuration, state: "state", interactionHandle: "foo", codeVerifier: "bar")
        client = IDXClientAPIMock(context: context)
        api = IDXClient.APIVersion1(with: configuration,
                                    session: session)
        api.client = client
    }

    func testCurrentAuthenticatorWithoutRelatesTo() throws {
        let response = try XCTUnwrap(IDXClient.Response.response(client: client,
                                                                 fileName: "identify-single-form-response"))
        XCTAssertEqual(response.authenticators.count, 1)
        XCTAssertEqual(response.authenticators.first?.type, .password)
        
        let remediation = try XCTUnwrap(response.remediations[.identify])
        XCTAssertEqual(remediation.authenticators.count, 1)
        XCTAssertEqual(remediation.authenticators.first?.type, .password)
    }
}
