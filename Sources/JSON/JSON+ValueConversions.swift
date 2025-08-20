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

extension JSON.Primitive: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON.Primitive: ExpressibleByExtendedGraphemeClusterLiteral {
    @inlinable
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension JSON.Primitive: ExpressibleByUnicodeScalarLiteral {
    @inlinable
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
}

extension JSON.Primitive: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension JSON.Primitive: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension JSON.Primitive: ExpressibleByBooleanLiteral {
    @inlinable
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON.Primitive: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON.Value: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self = .primitive(.string(value))
    }
}

extension JSON.Value: ExpressibleByExtendedGraphemeClusterLiteral {
    @inlinable
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .primitive(.string(value))
    }
}

extension JSON.Value: ExpressibleByUnicodeScalarLiteral {
    @inlinable
    public init(unicodeScalarLiteral value: String) {
        self = .primitive(.string(value))
    }
}

extension JSON.Value: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int) {
        self = .primitive(.int(value))
    }
}

extension JSON.Value: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self = .primitive(.double(value))
    }
}

extension JSON.Value: ExpressibleByBooleanLiteral {
    @inlinable
    public init(booleanLiteral value: Bool) {
        self = .primitive(.bool(value))
    }
}

extension JSON.Value: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .primitive(.null)
    }
}

extension JSON.Value: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: JSON.Value...) {
        self = .array(elements)
    }
}

extension JSON.Value: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (String, JSON.Value)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension JSON: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: JSON.Value...) {
        self = JSON(.array(elements))
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (String, JSON.Value)...) {
        self = JSON(.object(Dictionary(uniqueKeysWithValues: elements)))
    }
}
