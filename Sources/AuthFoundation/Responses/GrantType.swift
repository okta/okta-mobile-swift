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

public enum GrantType: Codable, Hashable {
    case authorizationCode
    case implicit
    case refreshToken
    case password
    case other(_ type: String)
}

fileprivate let Mapping: [String:GrantType] = [
    "authorization_code": .authorizationCode,
    "implicit": .implicit,
    "refresh_token": .refreshToken,
    "password": .password
]

extension GrantType: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        if let mapping = Mapping[rawValue] {
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
        }
    }
}
