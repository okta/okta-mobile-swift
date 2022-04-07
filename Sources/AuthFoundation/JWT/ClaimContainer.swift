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

/// Protocol used to define shared behavior when an object can contain claims.
///
/// > Note: This does not apply to JWT, which while it contains claims, it has a different format which includes headers and signatures.
public protocol ClaimContainer: JSONDecodable {
    var payload: [String: Any] { get }
}

extension ClaimContainer {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONCodingKeys.self)
        try payload
            .compactMap { (key: String, value: Any) in
                guard let key = JSONCodingKeys(stringValue: key) else { return nil }
                return (key, value)
            }
            .forEach { (key: JSONCodingKeys, value: Any) in
                if let value = value as? Bool {
                    try container.encode(value, forKey: key)
                } else if let value = value as? String {
                    try container.encode(value, forKey: key)
                } else if let value = value as? Int {
                    try container.encode(value, forKey: key)
                } else if let value = value as? Double {
                    try container.encode(value, forKey: key)
                } else if let value = value as? [String: String] {
                    try container.encode(value, forKey: key)
                }
            }
    }

    /// Returns the list of all claims contained within this ``UserInfo``.
    public var claims: [Claim] {
        payload.keys.compactMap { Claim(rawValue: $0) }
    }
    
    /// Returns the list of custom claims this instance might contain.
    public var customClaims: [String] {
        payload.keys.filter { Claim(rawValue: $0) == nil }
    }
    
    /// Returns the value for the supplied key, of the expected type.
    /// - Returns: Value, or `nil` if the key doesn't exist, or is of a different value.
    public func value<T>(_ type: T.Type, for key: String) -> T? {
        payload[key] as? T
    }
}
