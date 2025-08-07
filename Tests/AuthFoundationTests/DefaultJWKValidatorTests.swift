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
import Testing

@testable import TestCommon
@testable import AuthFoundation

@Suite("Default JWK validator", .disabled("Debugging test deadlocks within CI"))
struct DefaultJWKValidatorTests {
    let keySet = """
        {
            "keys" : [
               {
                  "alg" : "RS256",
                  "e" : "AQAB",
                  "kid" : "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA",
                  "kty" : "RSA",
                  "n" : "ANsXAmcnHqXgurW2yJXSendqjDf2m7DZL_OIfTQP1Mzpa2wYpd2ZYWf9eO9XzkkN7SY0_ujnDiB9Vqdybzrq86bqBqykchyX5Dw-ozaBm_uQptpwjOZOASYyuKUv1-n5DYWGTutldY0fK1TULbhPjgBow1-kKn4QRWbIpknHwRdaAOMJnUyB3X5ssMHk9LkKBpptCspp3PAOEZ9xq6eq25jJvXK5Rd8QvgIJW-JB2-S0Z4Mj77z9R3CObzaYew6NPbf-i5vlnOfWSyoYHiS1xIQmTnlMTKNOPEf7y5DbauUlCvYJUN75TmR5eJXYbwkoSrgbchYppKp5C-gEY2A7DPk",
                  "use" : "sig"
               }
            ]
         }
        """

    @Test("Successful validation")
    func testValidator() throws {
        let keyData = data(for: keySet)
        let jwks = try JSONDecoder().decode(JWKS.self, from: keyData)
        let jwt = try JWT(String.mockIdToken)
        let validator = DefaultJWKValidator()

        #if os(Linux) || os(Android)
        let error = #expect(throws: JWTError.self) {
            try validator.validate(token: jwt, using: jwks)
        }
        #expect(error == .signatureVerificationUnavailable)
        #else
        try validator.validate(token: jwt, using: jwks)
        #endif
    }
    
    #if !os(Linux)
    @Test("Invalid algorithm")
    func testInvalidAlgorithm() throws {
        let jwks = try JSONDecoder().decode(JWKS.self, from: data(for: """
            {
                "keys" : [
                   {
                      "kid" : "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA",
                      "kty" : "RSA",
                      "use" : "sig"
                   }
                ]
             }
            """))

        let jwt = try JWT(String.mockIdToken)
        let validator = DefaultJWKValidator()
        let error = #expect(throws: JWTError.self) {
            try validator.validate(token: jwt, using: jwks)
        }
        #expect(error == .invalidKey)
    }

    @Test("Invalid key ID")
    func testInvalidKey() throws {
        let jwks = try JSONDecoder().decode(JWKS.self, from: data(for: """
            {
                "keys" : [
                   {
                      "alg" : "RS256",
                      "kid" : "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA",
                      "kty" : "RSA",
                      "use" : "sig"
                   }
                ]
             }
            """))
        let jwt = try JWT(String.mockIdToken)
        let validator = DefaultJWKValidator()
        let error = #expect(throws: JWTError.self) {
            try validator.validate(token: jwt, using: jwks)
        }
        #expect(error == .invalidKey)
    }

    @Test("Error creating key")
    func testInvalidCannotCreateKey() throws {
        let jwks = try JSONDecoder().decode(JWKS.self, from: data(for: """
            {
                "keys" : [
                   {
                      "alg" : "RS256",
                      "kid" : "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA",
                      "kty" : "RSA",
                      "e" : "thisisincorrect",
                      "n" : "thisisincorrect",
                      "use" : "sig"
                   }
                ]
             }
            """))
        let jwt = try JWT(String.mockIdToken)
        let validator = DefaultJWKValidator()
        let error = #expect(throws: JWTError.self) {
            try validator.validate(token: jwt, using: jwks)
        }
        #expect(error == .cannotCreateKey(
            code: -50,
            description: "The operation couldn’t be completed. (OSStatus error -50 - RSA public key creation from data failed)"))
    }

    @Test("Unsupported signing algorithm")
    func testInvalidSigningAlgorithm() throws {
        let jwks = try JSONDecoder().decode(JWKS.self, from: data(for: """
            {
                "keys" : [
                   {
                      "alg" : "ES256",
                      "kid" : "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA",
                      "kty" : "RSA",
                      "e" : "AQAB",
                      "n" : "ANsXAmcnHqXgurW2yJXSendqjDf2m7DZL_OIfTQP1Mzpa2wYpd2ZYWf9eO9XzkkN7SY0_ujnDiB9Vqdybzrq86bqBqykchyX5Dw-ozaBm_uQptpwjOZOASYyuKUv1-n5DYWGTutldY0fK1TULbhPjgBow1-kKn4QRWbIpknHwRdaAOMJnUyB3X5ssMHk9LkKBpptCspp3PAOEZ9xq6eq25jJvXK5Rd8QvgIJW-JB2-S0Z4Mj77z9R3CObzaYew6NPbf-i5vlnOfWSyoYHiS1xIQmTnlMTKNOPEf7y5DbauUlCvYJUN75TmR5eJXYbwkoSrgbchYppKp5C-gEY2A7DPk",
                      "use" : "sig"
                   }
                ]
             }
            """))
        let jwt = try JWT(String.mockIdToken)
        let validator = DefaultJWKValidator()
        let error = #expect(throws: JWTError.self) {
            try validator.validate(token: jwt, using: jwks)
        }
        #expect(error == .invalidSigningAlgorithm)
    }
#endif
}
