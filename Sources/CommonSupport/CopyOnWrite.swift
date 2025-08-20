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

@_documentation(visibility: internal)
public struct CopyOnWrite<T> {
    nonisolated(unsafe) private var _ref: Reference
    private let lock = Lock()

    public static func === (lhs: CopyOnWrite<T>, rhs: CopyOnWrite<T>) -> Bool {
        lhs._ref === rhs._ref
    }

    public static func !== (lhs: CopyOnWrite<T>, rhs: CopyOnWrite<T>) -> Bool {
        lhs._ref !== rhs._ref
    }

    @_documentation(visibility: internal)
    public init(_ value: T) {
        _ref = Reference(value: value)
    }
    
    @_documentation(visibility: internal)
    public var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            
            return _ref.value
        }
        
        set {
            lock.lock()
            defer { lock.unlock() }

            guard isKnownUniquelyReferenced(&_ref) else {
                _ref = Reference(value: newValue)
                return
            }
            _ref.value = newValue
        }
    }

    @_documentation(visibility: internal)
    public mutating func modify<Output>(_ modify: (inout T) throws -> Output) rethrows -> Output {
        lock.lock()
        defer { lock.unlock() }

        if !isKnownUniquelyReferenced(&_ref) {
            _ref = Reference(value: _ref.value)
        }
        
        return try modify(&_ref.value)
    }

    private final class Reference {
        var value: T
        
        init(value: T) {
            self.value = value
        }
    }
}

extension CopyOnWrite: Sendable where T: Sendable {}
