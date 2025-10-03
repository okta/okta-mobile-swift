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

extension JSONPrimitiveConvertible {
    @inlinable public var jsonValue: JSON.Value {
        .primitive(primitive)
    }
}

extension JSON.Primitive: JSONPrimitiveConvertible {
    @inlinable public var primitive: JSON.Primitive { self }
}

extension JSON.Value: JSONValueConvertible {
    @inlinable public var jsonValue: JSON.Value { self }
}

extension String: JSONPrimitiveConvertible {
    @inlinable public var primitive: JSON.Primitive { .string(self) }
}

extension Int: JSONPrimitiveConvertible {
    @inlinable public var primitive: JSON.Primitive { .int(self) }
}

extension Double: JSONPrimitiveConvertible {
    @inlinable public var primitive: JSON.Primitive { .double(self) }
}

extension Bool: JSONPrimitiveConvertible {
    @inlinable public var primitive: JSON.Primitive { .bool(self) }
}

extension NSNull: JSONPrimitiveConvertible {
    @inlinable public var primitive: JSON.Primitive { .null }
}

extension Array<JSONValueConvertible>: JSONValueConvertible, JSONRootValue {
    @inlinable public var jsonValue: JSON.Value {
        .array(compactMap(\.jsonValue))
    }
}

extension Dictionary<String, JSONValueConvertible>: JSONValueConvertible, JSONRootValue {
    @inlinable public var jsonValue: JSON.Value {
        .object(self.mapValues(\.jsonValue))
    }
}
