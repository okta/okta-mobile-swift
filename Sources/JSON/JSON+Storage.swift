//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension JSON {
    /// Indicates the underlying representation used to initialize this ``JSON`` object.
    public enum Representation: Sendable {
        case json(Value)
        case data(Data)
        
        var data: Data {
            get throws {
                switch self {
                case .json(let value):
                    guard let anyValue = value.anyValue else {
                        throw JSONError.invalidJSONValue
                    }

                    return try JSONSerialization.data(withJSONObject: anyValue,
                                                      options: .sortedKeys)

                case .data(let data):
                    return data
                }
            }
        }
    }
    
    struct Storage: Sendable {
        private(set) var representation: Representation

        var data: Data {
            get throws {
                if case let .data(data) = representation {
                    return data
                }
                
                var result = self
                return try result.render()
            }
        }

        var value: Value {
            didSet {
                representation = .json(value)
            }
        }

        mutating func render() throws -> Data {
            if case let .data(data) = representation {
                return data
            }
            
            let data = try representation.data
            self.representation = .data(data)
            return data
        }

        init(_ string: String) throws {
            try self.init(Data(string.utf8))
        }
        
        init(_ value: any JSONRootValue) {
            self.value = value.jsonValue
            self.representation = .json(self.value)
        }

        init(_ data: Data) throws {
            self.value = try .init(JSONSerialization.jsonObject(with: data, options: []))
            self.representation = .data(data)
        }

        init(_ value: Any) throws {
            guard Primitive._valueFromAny(value) == nil else {
                throw JSONError.unsupportedRootValue
            }
            
            self.value = try Value(value)
            if case .primitive(_) = self.value {
                throw JSONError.unsupportedRootValue
            }
            self.representation = .json(self.value)
        }

        init(_ value: Value) {
            self.value = value
            self.representation = .json(value)
        }
    }
}

extension JSON.Representation: Equatable {
    public static func == (lhs: JSON.Representation, rhs: JSON.Representation) -> Bool {
        switch (lhs, rhs) {
        case (.json(let lhsValue), .json(let rhsValue)):
            return lhsValue == rhsValue
        case (.data(let lhsData), .data(let rhsData)):
            return lhsData == rhsData
        case (.data(let lhsData), .json(let rhsValue)):
            if let rhsData = try? JSONSerialization.data(withJSONObject: rhsValue.anyValue as Any, options: []) {
                return lhsData == rhsData
            }
            return false
        case (.json(let lhsValue), .data(let rhsData)):
            if let lhsData = try? JSONSerialization.data(withJSONObject: lhsValue.anyValue as Any, options: []) {
                return lhsData == rhsData
            }
            return false
        }
    }
}
