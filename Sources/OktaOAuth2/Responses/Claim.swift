//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public enum Claim: Codable, Hashable {
    case issuer
    case subject
    case audience
    case expirationTime
    case notBefore
    case issuedAt
    case jwtID
    case nonce
    case authenticationMethodsReference
    case claim(_ name: String)
}

fileprivate let Mapping: [String:Claim] = [
    "iss":   .issuer,
    "sub":   .subject,
    "aud":   .audience,
    "exp":   .expirationTime,
    "nbf":   .notBefore,
    "iat":   .issuedAt,
    "jti":   .jwtID,
    "nonce": .nonce,
    "amr":   .authenticationMethodsReference
]

extension Claim: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        if let claim = Mapping[rawValue] {
            self = claim
        } else {
            self = .claim(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .claim(let name):
            return name
        default:
            return Mapping.first { $0.value == self }?.key ?? ""
        }
    }
}
