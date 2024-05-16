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
    public enum Algorithm: Codable {
        // JWS Algorithms according to https://www.rfc-editor.org/rfc/rfc7518.html#section-3.1
        case hs256
        case hs384
        case hs512
        case rs256
        case rs384
        case rs512
        case es256
        case es384
        case es512
        case ps256
        case ps384
        case ps512
        case none
        
        // JWE Algorithms according to https://www.rfc-editor.org/rfc/rfc7518.html#section-4.1
        case rsa1_5
        case rsaOAEP
        case rsaOAEP256
        case a128KW
        case a192KW
        case a256KW
        case dir
        case ecdhES
        case ecdhES_a128KW
        case ecdhES_a192KW
        case ecdhES_a256KW
        case edDSA
        case a128GCMKW
        case a192GCMKW
        case a256GCMKW
        case pbes2_HS256_A128KW
        case pbes2_HS384_A192KW
        case pbes2_HS512_A256KW
        
        case other(algorithm: String)
    }
    // swiftlint:enable identifier_name
}
