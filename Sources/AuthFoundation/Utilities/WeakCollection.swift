//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Property wrapper representing a weak value.
@_documentation(visibility: internal)
@propertyWrapper
public struct Weak<Object: AnyObject>: Sendable {
    public var wrappedValue: Object? {
        get { lock.withLock { _wrappedValue } }
        set { lock.withLock { _wrappedValue = newValue } }
    }

    nonisolated(unsafe) private weak var _wrappedValue: Object?
    private let lock = Lock()
    public init?(_ object: Object?) {
        guard let object = object else {
            return nil
        }

        _wrappedValue = object
    }
}

extension Weak: Hashable where Object: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension Weak: Equatable where Object: Equatable {
    public static func == (lhs: Weak<Object>, rhs: Weak<Object>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

/// Property wrapper representing a collection of weak values.
@_documentation(visibility: internal)
@propertyWrapper
public struct WeakCollection<Collect, Element>: Sendable where Collect: RangeReplaceableCollection, Collect.Element == Element?, Element: AnyObject {
    private var weakObjects = [Weak<Element>]()

    public init(wrappedValue value: Collect) { save(collection: value) }

    private mutating func save(collection: Collect) {
        weakObjects = collection.compactMap { Weak($0) }
    }

    public var wrappedValue: Collect {
        get { Collect(weakObjects.compactMap(\.wrappedValue)) }
        set (newValues) { save(collection: newValues) }
    }
}

extension WeakCollection: Hashable where Collect: Equatable, Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(weakObjects)
    }
}

extension WeakCollection: Equatable where Collect: Equatable, Element: Hashable {
    public static func == (lhs: WeakCollection<Collect, Element>, rhs: WeakCollection<Collect, Element>) -> Bool {
        Set(lhs.weakObjects) == Set(rhs.weakObjects)
    }
}
