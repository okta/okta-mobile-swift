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

class IDXResponseCodableTests: XCTestCase {
    let configuration = IDXClient.Configuration(issuer: "issuer",
                                                clientId: "client",
                                                clientSecret: nil,
                                                scopes: ["scope"],
                                                redirectUri: "redirect")
    
    func testContextCodable() throws {
        let object = IDXClient.Context(configuration: configuration,
                                       state: "state",
                                       interactionHandle: "handle",
                                       codeVerifier: "verifier")
        let data = try JSONEncoder().encode(object)
        let result = try JSONDecoder().decode(IDXClient.Context.self, from: data)
        XCTAssertEqual(object, result)
    }

    func testTokenCodable() throws {
        let object = IDXClient.Token(accessToken: "access",
                                     refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type",
                                     configuration: configuration)
        let data = try JSONEncoder().encode(object)
        let result = try JSONDecoder().decode(IDXClient.Token.self, from: data)
        XCTAssertEqual(object, result)
    }

    @available(iOS 11.0, *)
    func testContextSecureCoding() throws {
        let object = IDXClient.Context(configuration: configuration,
                                       state: "state",
                                       interactionHandle: "handle",
                                       codeVerifier: "verifier")
        let data = try NSKeyedArchiver.archivedData(withRootObject: object,
                                                    requiringSecureCoding: true)
        let result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? IDXClient.Context
        XCTAssertEqual(object, result)
    }
    
    @available(iOS 11.0, *)
    func testTokenSecureCoding() throws {
        let object = IDXClient.Token(accessToken: "access",
                                     refreshToken: "refresh",
                                     expiresIn: 10,
                                     idToken: "foo",
                                     scope: "bar",
                                     tokenType: "type",
                                     configuration: configuration)
        let data = try NSKeyedArchiver.archivedData(withRootObject: object,
                                                    requiringSecureCoding: true)
        let result = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? IDXClient.Token
        XCTAssertEqual(object, result)
    }
}
