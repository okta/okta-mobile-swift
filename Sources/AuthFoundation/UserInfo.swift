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

/// User profile information.
///
/// This provides a convenience mechanism for accessing information related to a user. It supports the ``HasClaims`` protocol, to simplify common operations against user information, and to provide consistency with the ``JWT`` class.
public struct UserInfo: RawRepresentable, Codable, HasClaims {
    public typealias RawValue = [String:Any]
    public let rawValue: RawValue
    
    /// Returns the list of all claims contained within this ``UserInfo``.
    public var claims: [Claim] {
        rawValue.keys.compactMap { Claim(rawValue: $0) }
    }
    
    /// Returns the list of custom claims this ``UserInfo`` instance might contain.
    public var customClaims: [String] {
        rawValue.keys.filter { Claim(rawValue: $0) == nil }
    }

    public func value<T>(_ type: T.Type, for key: String) -> T? {
        rawValue[key] as? T
    }

    public init?(rawValue: RawValue) {
        self.init(rawValue)
    }
    
    public init(_ info: RawValue) {
        self.rawValue = info
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
        self.init(try container.decode([String:Any].self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONCodingKeys.self)
        _ = try rawValue.compactMap({ (key: String, value: Any) in
            guard let key = JSONCodingKeys(stringValue: key) else { return nil }
            return (key, value)
        }).map({ (key: JSONCodingKeys, value: Any) in
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? [String:String] {
                try container.encode(value, forKey: key)
            }
        })
    }
}

extension UserInfo: JSONDecodable {
    public static var jsonDecoder = JSONDecoder()
}
