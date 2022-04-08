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

@propertyWrapper
public struct TimeSensitive<T: Codable>: Codable {
    public private(set) var updatedAt: Date?

    var storedValue: T
    
    public var wrappedValue: T {
        get {
            storedValue
        }
        set {
            storedValue = newValue
            updatedAt = Date.nowCoordinated
        }
    }
    
    public init(wrappedValue: T) {
        storedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        storedValue = try container.decode(T.self, forKey: .storedValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(storedValue, forKey: .storedValue)
    }

    enum CodingKeys: String, CodingKey {
        case updatedAt
        case storedValue
    }
}
