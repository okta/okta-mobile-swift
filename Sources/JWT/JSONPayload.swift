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

//extension Dictionary<String, Any> {
//    public static func decodeJSONObject(from decoder: Decoder) throws -> [String: any Sendable] {
//        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
//        return try container.decode([String: Any].self)
//    }
//
//    public static func encodeJSONObject(_ object: [String: any Sendable], to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: JSONCodingKeys.self)
//        try object
//            .compactMap { (key: String, value: Any) in
//                guard let key = JSONCodingKeys(stringValue: key) else { return nil }
//                return (key, value)
//            }
//            .forEach { (key: JSONCodingKeys, value: Any) in
//                if let value = value as? Bool {
//                    try container.encode(value, forKey: key)
//                } else if let value = value as? String {
//                    try container.encode(value, forKey: key)
//                } else if let value = value as? Int {
//                    try container.encode(value, forKey: key)
//                } else if let value = value as? Double {
//                    try container.encode(value, forKey: key)
//                } else if let value = value as? [String: String] {
//                    try container.encode(value, forKey: key)
//                }
//            }
//    }
//
//}
