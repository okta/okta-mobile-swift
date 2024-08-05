//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

// swiftlint:disable cyclomatic_complexity
extension JWK.Algorithm: RawRepresentable, Equatable, Hashable, ClaimConvertable {
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "HS256": self = .hs256
        case "HS384": self = .hs384
        case "HS512": self = .hs512
        case "RS256": self = .rs256
        case "RS384": self = .rs384
        case "RS512": self = .rs512
        case "ES256": self = .es256
        case "ES384": self = .es384
        case "ES512": self = .es512
        case "PS256": self = .ps256
        case "PS384": self = .ps384
        case "PS512": self = .ps512
        case "RSA1_5": self = .rsa1_5
        case "RSA-OAEP": self = .rsaOAEP
        case "RSA-OAEP-256": self = .rsaOAEP256
        case "A128KW": self = .a128KW
        case "A192KW": self = .a192KW
        case "A256KW": self = .a256KW
        case "dir": self = .dir
        case "ECDH-ES": self = .ecdhES
        case "ECDH-ES+A128KW": self = .ecdhES_a128KW
        case "ECDH-ES+A192KW": self = .ecdhES_a192KW
        case "ECDH-ES+A256KW": self = .ecdhES_a256KW
        case "EdDSA": self = .edDSA
        case "A128GCMKW": self = .a128GCMKW
        case "A192GCMKW": self = .a192GCMKW
        case "A256GCMKW": self = .a256GCMKW
        case "PBES2-HS256+A128KW": self = .pbes2_HS256_A128KW
        case "PBES2-HS384+A192KW": self = .pbes2_HS384_A192KW
        case "PBES2-HS512+A256KW": self = .pbes2_HS512_A256KW
        default: self = .other(algorithm: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .hs256: return "HS256"
        case .hs384: return "HS384"
        case .hs512: return "HS512"
        case .rs256: return "RS256"
        case .rs384: return "RS384"
        case .rs512: return "RS512"
        case .es256: return "ES256"
        case .es384: return "ES384"
        case .es512: return "ES512"
        case .ps256: return "PS256"
        case .ps384: return "PS384"
        case .ps512: return "PS512"
        case .rsa1_5: return "RSA1_5"
        case .rsaOAEP: return "RSA-OAEP"
        case .rsaOAEP256: return "RSA-OAEP-256"
        case .a128KW: return "A128KW"
        case .a192KW: return "A192KW"
        case .a256KW: return "A256KW"
        case .dir: return "dir"
        case .ecdhES: return "ECDH-ES"
        case .ecdhES_a128KW: return "ECDH-ES+A128KW"
        case .ecdhES_a192KW: return "ECDH-ES+A192KW"
        case .ecdhES_a256KW: return "ECDH-ES+A256KW"
        case .edDSA: return "EdDSA"
        case .a128GCMKW: return "A128GCMKW"
        case .a192GCMKW: return "A192GCMKW"
        case .a256GCMKW: return "A256GCMKW"
        case .pbes2_HS256_A128KW: return "PBES2-HS256+A128KW"
        case .pbes2_HS384_A192KW: return "PBES2-HS384+A192KW"
        case .pbes2_HS512_A256KW: return "PBES2-HS512+A256KW"
        case .other(algorithm: let value): return value
        case .none: return ""
        }
    }
}
// swiftlint:enable cyclomatic_complexity
