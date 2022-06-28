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
@testable import OktaIdx

class IDXResponseEqualityTests: XCTestCase {
    func testContextEquality() throws {
        let pkce = try XCTUnwrap(PKCE())
        let compare = IDXAuthenticationFlow.Context(interactionHandle: "handle",
                                                    state: "state",
                                                    pkce: pkce)
        
        var object = IDXAuthenticationFlow.Context(interactionHandle: "handle2",
                                                   state: "state",
                                                   pkce: pkce)
        XCTAssertNotEqual(compare, object)
        
        object = IDXAuthenticationFlow.Context(interactionHandle: "handle",
                                               state: "state",
                                               pkce: pkce)
        XCTAssertEqual(compare, object)
        
        
        object = IDXAuthenticationFlow.Context(interactionHandle: "handle",
                                               state: "state2",
                                               pkce: pkce)
        XCTAssertNotEqual(compare, object)
        
        object = IDXAuthenticationFlow.Context(interactionHandle: "handle",
                                               state: "state",
                                               pkce: pkce)
        XCTAssertEqual(compare, object)
    }
}
