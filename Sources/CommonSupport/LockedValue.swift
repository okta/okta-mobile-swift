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

@propertyWrapper
@_documentation(visibility: private)
public final class LockedValue<Value: Sendable>: @unchecked Sendable {
    public var wrappedValue: Value {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }

    public init(wrappedValue: Value) {
        _value = wrappedValue
    }

    public init(_ value: Value) {
        _value = value
    }

    // MARK: Private properties / methods
    private let lock = Lock()
    nonisolated(unsafe) private var _value: Value
}

extension LockedValue: ExpressibleByIntegerLiteral where Value: ExpressibleByIntegerLiteral {
    @inlinable
    public convenience init(integerLiteral value: Value.IntegerLiteralType) {
        self.init(.init(integerLiteral: value))
    }
}

extension LockedValue: ExpressibleByFloatLiteral where Value: ExpressibleByFloatLiteral {
    @inlinable
    public convenience init(floatLiteral value: Value.FloatLiteralType) {
        self.init(.init(floatLiteral: value))
    }
}

extension LockedValue: ExpressibleByBooleanLiteral where Value: ExpressibleByBooleanLiteral {
    @inlinable
    public convenience init(booleanLiteral value: Value.BooleanLiteralType) {
        self.init(.init(booleanLiteral: value))
    }
}

extension LockedValue: ExpressibleByNilLiteral where Value: ExpressibleByNilLiteral {
    @inlinable
    public convenience init(nilLiteral: ()) {
        self.init(nil)
    }
}
