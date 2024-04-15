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

public enum GrantType: Codable, Hashable, IsClaim {
    case authorizationCode
    case implicit
    case refreshToken
    case password
    case deviceCode
    case tokenExchange
    case otp
    case oob
    case otpMFA
    case oobMFA
    case webAuthn
    case webAuthnMFA
    case other(_ type: String)
}

private let grantTypeMapping: [String: GrantType] = [
    "authorization_code": .authorizationCode,
    "implicit": .implicit,
    "refresh_token": .refreshToken,
    "password": .password,
    "urn:ietf:params:oauth:grant-type:token-exchange": .tokenExchange,
    "urn:ietf:params:oauth:grant-type:device_code": .deviceCode,
    "urn:okta:params:oauth:grant-type:otp": .otp,
    "urn:okta:params:oauth:grant-type:oob": .oob,
    "http://auth0.com/oauth/grant-type/mfa-otp": .otpMFA,
    "http://auth0.com/oauth/grant-type/mfa-oob": .oobMFA,
    "urn:okta:params:oauth:grant-type:webauthn": .webAuthn,
    "urn:okta:params:oauth:grant-type:mfa-webauthn": .webAuthnMFA,
]

extension GrantType: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        if let mapping = grantTypeMapping[rawValue] {
            self = mapping
        } else {
            self = .other(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .other(let name):
            return name
        case .authorizationCode:
            return "authorization_code"
        case .implicit:
            return "implicit"
        case .refreshToken:
            return "refresh_token"
        case .password:
            return "password"
        case .tokenExchange:
            return "urn:ietf:params:oauth:grant-type:token-exchange"
        case .deviceCode:
            return "urn:ietf:params:oauth:grant-type:device_code"
        case .otp:
            return "urn:okta:params:oauth:grant-type:otp"
        case .oob:
            return "urn:okta:params:oauth:grant-type:oob"
        case .otpMFA:
            return "http://auth0.com/oauth/grant-type/mfa-otp"
        case .oobMFA:
            return "http://auth0.com/oauth/grant-type/mfa-oob"
        case .webAuthn:
            return "urn:okta:params:oauth:grant-type:webauthn"
        case .webAuthnMFA:
            return "urn:okta:params:oauth:grant-type:mfa-webauthn"
        }
    }
}
