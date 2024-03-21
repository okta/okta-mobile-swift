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

extension JWK {
    /// The type of JWK key.
    public enum KeyType: String, Codable {
        case ellipticCurve = "EC"
        case rsa = "RSA"
        case octetSequence = "oct"
    }
    
    /// The intended usage for this key (e.g. signing or encryption).
    public enum Usage: String, Codable {
        case signature = "sig"
        case encryption = "enc"
    }
    
    // swiftlint:disable identifier_name
    /// The algorithm this key is intended to be used with.
    public enum Algorithm: String, Codable {
        // JWS Algorithms according to https://www.rfc-editor.org/rfc/rfc7518.html#section-3.1
        case hs256 = "HS256"
        case hs384 = "HS384"
        case hs512 = "HS512"
        case rs256 = "RS256"
        case rs384 = "RS384"
        case rs512 = "RS512"
        case es256 = "ES256"
        case es384 = "ES384"
        case es512 = "ES512"
        case ps256 = "PS256"
        case ps384 = "PS384"
        case ps512 = "PS512"
        case none
        
        // JWE Algorithms according to https://www.rfc-editor.org/rfc/rfc7518.html#section-4.1
        case rsa1_5             = "RSA1_5"
        case rsaOAEP            = "RSA-OAEP"
        case rsaOAEP256         = "RSA-OAEP-256"
        case a128KW             = "A128KW"
        case a192KW             = "A192KW"
        case a256KW             = "A256KW"
        case dir                = "dir"
        case ecdhES             = "ECDH-ES"
        case ecdhES_a128KW      = "ECDH-ES+A128KW"
        case ecdhES_a192KW      = "ECDH-ES+A192KW"
        case ecdhES_a256KW      = "ECDH-ES+A256KW"
        case a128GCMKW          = "A128GCMKW"
        case a192GCMKW          = "A192GCMKW"
        case a256GCMKW          = "A256GCMKW"
        case pbes2_HS256_A128KW = "PBES2-HS256+A128KW"
        case pbes2_HS384_A192KW = "PBES2-HS384+A192KW"
        case pbes2_HS512_A256KW = "PBES2-HS512+A256KW"
    }
    // swiftlint:enable identifier_name
}
