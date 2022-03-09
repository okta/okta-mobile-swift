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

import Foundation
import XCTest
import TestCommon

@testable import AuthFoundation

final class JWKTests: XCTestCase {
    func testKeySets() throws {
        let keyData = try data(from: .module, for: "keys", in: "MockResponses")
        let jwks = try JSONDecoder().decode(JWKS.self, from: keyData)
        
        XCTAssertEqual(jwks.count, 1)
        
        let keyId = "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA"
        let key = try XCTUnwrap(jwks[keyId])
        XCTAssertEqual(key.id, keyId)
        XCTAssertEqual(key.type, .rsa)
        XCTAssertEqual(key.algorithm, .rs256)
        XCTAssertEqual(key.usage, .signature)
        XCTAssertNotNil(key.rsaModulus)
        XCTAssertEqual(key.rsaExponent, "AQAB")
        
        XCTAssertTrue(jwks[0] == key)
        
        let data = try JSONEncoder().encode(jwks)
        let decodedJwks = try JSONDecoder().decode(JWKS.self, from: data)
        XCTAssertEqual(jwks, decodedJwks)
    }
}
