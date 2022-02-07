//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@testable import OktaOAuth2

final class PKCETests: XCTestCase {
    func testPKCE() throws {
        guard let pkce = PKCE() else {
            XCTFail("Unable to create PKCE")
            return
        }
        
        XCTAssertNotNil(pkce.codeVerifier)
        
        #if os(Linux)
        XCTAssertNil(pkce.codeChallenge)
        XCTAssertEqual(pkce.method, .plain)
        #else
        XCTAssertNotNil(pkce.codeChallenge)
        XCTAssertEqual(pkce.method, .sha256)
        #endif
    }
}
