//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct AdditionalValuesCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}

extension KeyedDecodingContainer where Key == AdditionalValuesCodingKeys {
    func decodeUnkeyedContainer<T: CodingKey>(exclude keyedBy: T.Type) -> [String: Any] {
        var data = [String: Any]()
    
        for key in allKeys {
            if keyedBy.init(stringValue: key.stringValue) == nil {
                if let value = try? decode(String.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Bool.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Int.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Double.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Float.self, forKey: key) {
                    data[key.stringValue] = value
                }
            }
        }
    
        return data
    }
}
