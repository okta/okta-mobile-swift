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

/// An implementation of the Copy-on-Write (CoW) pattern that optimizes concurrent access for
/// value types, such as structs, that aims to improve performance and memory efficiency while
/// preserving value semantics.
/// 
/// This pattern is commonly used within Swift Foundation (such as Array, Dictionary, and String)
/// to provide efficient memory management and performance optimizations.
///
/// It achieves this by wrapping a reference type and ensuring that modifications to the value
/// only occur when the reference is shared with another instance. This means that if you have
/// multiple instances of `CopyOnWrite` that reference the same underlying value, modifications
/// will trigger a copy of the value, ensuring that each instance maintains its own unique copy
/// of the data.
///
/// ## Thread Safety
/// This type is thread-safe and can be used across multiple threads safely. All operations
/// are protected by an internal lock to ensure data consistency.
///
/// ## Example Usage
/// ```swift
/// var array1 = CopyOnWrite([1, 2, 3])
/// var array2 = array1  // No copying occurs here
/// print(array1 === array2)  // true
///
/// // Modification triggers copy-on-write
/// array2.append(4)  // This creates a new copy for array2
/// 
/// print(array1.value)  // [1, 2, 3]
/// print(array2.value)  // [1, 2, 3, 4]
/// print(array1 !== array2)  // true
/// ```
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

    /// Initializes a new `CopyOnWrite` instance wrapping the provided value.
    /// - Parameter value: The value to wrap with copy-on-write semantics.
    @_documentation(visibility: internal)
    public init(_ value: T) {
        _ref = Reference(value: value)
    }
    
    /// The wrapped value with copy-on-write semantics.
    ///
    /// Getting the value is always safe and returns the current value without copying.
    /// Setting the value may trigger a copy, but only if the current reference is shared
    /// with other `CopyOnWrite` instances. Mutations to an instance that is uniquely owned
    /// will modify the value in place without copying.
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

    /// Provides exclusive mutable access to the wrapped value through a closure.
    ///
    /// This method ensures that the value is uniquely referenced before providing
    /// mutable access. If the reference is shared, a copy is made first. The closure
    /// receives an `inout` parameter allowing direct mutation of the wrapped value.
    /// 
    /// This is useful for performing multiple mutations in a single atomic operation,
    /// ensuring that the value remains consistent throughout the modifications.
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
