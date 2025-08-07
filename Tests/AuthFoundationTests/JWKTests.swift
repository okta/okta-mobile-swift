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
import TestCommon

@testable import AuthFoundation

@Suite("JWK Tests", .disabled("Debugging test deadlocks within CI"))
struct JWKTests {
    @Test("Key Sets parsing and validation")
    func keySets() throws {
        let keyData = try data(from: Bundle.module, for: "keys", in: "MockResponses")
        let jwks = try JSONDecoder().decode(JWKS.self, from: keyData)
        
        #expect(jwks.count == 1)
        
        let keyId = "k6HN2DKok-kExjJGBLqgzByMCnN1RvzEOA-1ukTjexA"
        let key = try #require(jwks[keyId])
        #expect(key.id == keyId)
        #expect(key.type == JWK.KeyType.rsa)
        #expect(key.algorithm == JWK.Algorithm.rs256)
        #expect(key.usage == JWK.Usage.signature)
        #expect(key.rsaModulus != nil)
        #expect(key.rsaExponent == "AQAB")
        
        #expect(jwks[0] == key)
        
        let encodedData = try JSONEncoder().encode(jwks)
        let decodedJwks = try JSONDecoder().decode(JWKS.self, from: encodedData)
        #expect(jwks == decodedJwks)
    }
    
    @Test("Default RSA Algorithm Fallback")
    func defaultRSAAlgorithmFallback() throws {
        let keyData = data(for: """
            {
              "keys": [
                  {
                      "kty": "RSA",
                      "kid": "p014K-d3IwPWLc0od5LHM1s1u0YDqX4LIl1xg6ik3j4",
                      "use": "sig",
                      "e": "AQAB",
                      "n": "yUPh0wNqXh1CMSxzud4uHkfBKkNX7powR4cRS_i0VxkbiicbNZ0IQhw-enDhZieRti4NhygOJfN8DPmtHsWJxt_pCsibc--bNgylcESpn9K4OxtiQrjUvtRM4WX3PWsKUREDZ0Vp-WAXC2nibvqRP_Ky38DkZMinzvCLabr0IOzyGc9AJrUHib61X6FucSoLM_YrKi2hd2UUHqeGiZrmUcHCrgrxcJIBTSbJq47hZrFzFN5RDq0Ium-lm8DU3bfoSlyc7minHlCWcOd90LtjonIHYqUVlpRYUzj_n4AM7DPKI6DDxC0-hio37qxfdmV_5Zvo6fpxIe8EUbI-oUoS3Q"
                  }
              ]
            }
            """)
        let jwks = try JSONDecoder().decode(JWKS.self, from: keyData)
        
        #expect(jwks.count == 1)
        
        let keyId = "p014K-d3IwPWLc0od5LHM1s1u0YDqX4LIl1xg6ik3j4"
        let key = try #require(jwks[keyId])
        #expect(key.id == keyId)
        #expect(key.type == JWK.KeyType.rsa)
        #expect(key.algorithm == JWK.Algorithm.rs256)
        #expect(key.usage == JWK.Usage.signature)
        #expect(key.rsaModulus != nil)
        #expect(key.rsaExponent == "AQAB")
    }
    
    @Test("JWS and JWE Keys")
    func jWSAndJWEKeys() throws {
        let keyData = data(for: """
            {
               "keys" : [
                  {
                     "alg" : "RSA-OAEP",
                     "e" : "AQAB",
                     "kid" : "{removed}",
                     "kty" : "RSA",
                     "n" : "{removed}",
                     "use" : "enc",
                     "x5c" : [
                        "{removed}"
                     ],
                     "x5t" : "{removed}",
                     "x5t#S256" : "{removed}"
                  },
                  {
                     "alg" : "RS256",
                     "e" : "AQAB",
                     "kid" : "{removed}",
                     "kty" : "RSA",
                     "n" : "{removed}",
                     "use" : "sig",
                     "x5c" : [
                        "{removed}"
                     ],
                     "x5t" : "{removed}",
                     "x5t#S256" : "{removed}"
                  }
               ]
            }
        """)
        
        let jwks = try JSONDecoder().decode(JWKS.self, from: keyData)
        
        #expect(jwks.count == 2)
        #expect(jwks[0].algorithm == JWK.Algorithm.rsaOAEP)
        #expect(jwks[1].algorithm == JWK.Algorithm.rs256)
    }
}
