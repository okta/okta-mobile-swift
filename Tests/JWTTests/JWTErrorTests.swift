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
import JWT

final class JWTErrorTests: XCTestCase {
    func testJWTError() {
        XCTAssertNotEqual(JWTError.invalidBase64Encoding.errorDescription,
                          "jwt_invalid_base64_encoding")
        XCTAssertNotEqual(JWTError.badTokenStructure.errorDescription,
                          "jwt_bad_token_structure")
        XCTAssertNotEqual(JWTError.invalidIssuer.errorDescription,
                          "jwt_invalid_issuer")
        XCTAssertNotEqual(JWTError.invalidAudience.errorDescription,
                          "jwt_invalid_audience")
        XCTAssertNotEqual(JWTError.invalidSubject.errorDescription,
                          "jwt_invalid_subject")
        XCTAssertNotEqual(JWTError.invalidAuthenticationTime.errorDescription,
                          "jwt_invalid_authentication_time")
        XCTAssertNotEqual(JWTError.issuerRequiresHTTPS.errorDescription,
                          "jwt_issuer_requires_https")
        XCTAssertNotEqual(JWTError.invalidSigningAlgorithm.errorDescription,
                          "jwt_invalid_signing_algorithm")
        XCTAssertNotEqual(JWTError.expired.errorDescription,
                          "jwt_token_expired")
        XCTAssertNotEqual(JWTError.issuedAtTimeExceedsGraceInterval.errorDescription,
                          "jwt_issuedAt_time_exceeds_grace_interval")
        XCTAssertNotEqual(JWTError.nonceMismatch.errorDescription,
                          "jwt_nonce_mismatch")
        XCTAssertNotEqual(JWTError.invalidKey.errorDescription,
                          "jwt_invalid_key")
        XCTAssertNotEqual(JWTError.signatureInvalid.errorDescription,
                          "jwt_signature_invalid")
        XCTAssertNotEqual(JWTError.signatureVerificationUnavailable.errorDescription,
                          "jwt_signature_verification_unavailable")
        XCTAssertNotEqual(JWTError.cannotGenerateHash.errorDescription,
                          "jwt_cannot_generate_hash")

        XCTAssertNotEqual(JWTError.cannotCreateKey(code: 123, description: "Description").errorDescription,
                          "jwt_cannot_create_key")
        XCTAssertNotEqual(JWTError.unsupportedAlgorithm(.es384).errorDescription,
                          "jwt_unsupported_algorithm")
    }
}
