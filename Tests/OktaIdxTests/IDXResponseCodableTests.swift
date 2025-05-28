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
    func testContextCodable() throws {
        let pkce = try XCTUnwrap(PKCE())
        let object = InteractionCodeFlow.Context(interactionHandle: "handle",
                                                 recoveryToken: "recoveryToken",
                                                 state: "state",
                                                 pkce: pkce,
                                                 acrValues: "some:acr:value",
                                                 maxAge: 300,
                                                 nonce: "the_nonce",
                                                 additionalParameters: ["foo": "bar"])
        let data = try JSONEncoder().encode(object)
        let result = try JSONDecoder().decode(InteractionCodeFlow.Context.self, from: data)
        XCTAssertEqual(object, result)
    }
}
