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
import AuthFoundation
@testable import OktaIdxAuth

class IDXResponseEqualityTests: XCTestCase {
    typealias Context = InteractionCodeFlow.Context
    func testContextEquality() throws {
        let pkce = try XCTUnwrap(PKCE())
        let compare = Context(recoveryToken: nil,
                              state: "state",
                              pkce: pkce,
                              acrValues: "some_acr_value",
                              maxAge: 150,
                              nonce: "abcd123",
                              additionalParameters: [
                                "some": "value"
                              ])
        var object = compare
        XCTAssertEqual(compare, object)

        object.state = "state2"
        XCTAssertNotEqual(compare, object)

        object = compare
        object.interactionHandle = "handle2"
        XCTAssertNotEqual(compare, object)

        object = compare
        object.acrValues = nil
        XCTAssertNotEqual(compare, object)

        object = compare
        object.maxAge = nil
        XCTAssertNotEqual(compare, object)

        object = compare
        object.additionalParameters = ["some": "value2"]
        XCTAssertNotEqual(compare, object)
    }
}
