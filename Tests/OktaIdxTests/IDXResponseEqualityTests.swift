/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaIdx

class IDXResponseEqualityTests: XCTestCase {
    func testContextEquality() {
        let configuration = IDXClient.Configuration(issuer: "issuer",
                                                    clientId: "client",
                                                    clientSecret: nil,
                                                    scopes: ["scope"],
                                                    redirectUri: "redirect")

        let compare = IDXClient.Context(configuration: configuration,
                                        state: "state",
                                        interactionHandle: "handle",
                                        codeVerifier: "verifier")
        XCTAssertNotEqual(compare as NSObject, "Foo" as NSObject)
        
        var object = IDXClient.Context(configuration: configuration,
                                       state: "state",
                                       interactionHandle: "handle2",
                                       codeVerifier: "verifier2")
        XCTAssertNotEqual(compare, object)
        
        object = IDXClient.Context(configuration: configuration,
                                   state: "state",
                                   interactionHandle: "handle",
                                   codeVerifier: "verifier2")
        XCTAssertNotEqual(compare, object)
        

        object = IDXClient.Context(configuration: configuration,
                                   state: "state2",
                                   interactionHandle: "handle",
                                   codeVerifier: "verifier")
        XCTAssertNotEqual(compare, object)
        
        object = IDXClient.Context(configuration: configuration,
                                   state: "state",
                                   interactionHandle: "handle",
                                   codeVerifier: "verifier")
        XCTAssertEqual(compare, object)
    }

    func testTokenEquality() throws {
        let configuration = IDXClient.Configuration(issuer: "issuer",
                                                    clientId: "client",
                                                    clientSecret: nil,
                                                    scopes: ["scope"],
                                                    redirectUri: "redirect")
        let compare = IDXClient.Token(accessToken: "access",
                                     refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type",
                                     configuration: configuration)
        XCTAssertNotEqual(compare as NSObject, "Foo" as NSObject)

        var object = IDXClient.Token(accessToken: "access2",
                                     refreshToken: "refresh2",
                                     expiresIn: 100,
                                     idToken: "foo2",
                                     scope: "bar2",
                                     tokenType: "type2",
                                     configuration: configuration)
        XCTAssertNotEqual(compare, object)

        object = IDXClient.Token(accessToken: "access",
                                     refreshToken: nil,
                                     expiresIn: 10,
                                     idToken: nil,
                                     scope: "bar",
                                     tokenType: "type",
                                     configuration: configuration)
        XCTAssertNotEqual(compare, object)

        object = IDXClient.Token(accessToken: "access",
                                 refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type",
                                     configuration: configuration)
        XCTAssertEqual(compare, object)
    }
}
