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

/// Indicates the class contains a collection of delegates, and the necessary convenience functions to add and remove delegates from the collection.
public protocol UsesDelegateCollection {
    associatedtype Delegate

    /// Adds the given argument as a delegate.
    /// - Parameter delegate: Delegate to add to the collection.
    func add(delegate: Delegate)
    
    /// Removes the given argument from the collection of delegates.
    /// - Parameter delegate: Delegate to remove from the collection.
    func remove(delegate: Delegate)

    /// The collection of delegates this flow notifies for key authentication events.
    var delegateCollection: DelegateCollection<Delegate> { get }
}

extension UsesDelegateCollection {
    public func add(delegate: Delegate) { delegateCollection.add(delegate) }
    public func remove(delegate: Delegate) { delegateCollection.remove(delegate) }
}

public final class DelegateCollection<Delegate>: Sendable {
    nonisolated(unsafe) private var delegates = [DelegateCollectionNode<Delegate>]()
    private let lock = Lock()
    
    public init() {}
}

extension DelegateCollection {
    /// Adds the given argument as a delegate.
    /// - Parameter delegate: Delegate to add to the collection.
    public func add(_ delegate: Delegate) {
        lock.withLock {
            delegates.append(.init(value: delegate as AnyObject))
        }
    }
    
    /// Removes the given argument from the collection of delegates.
    /// - Parameter delegate: Delegate to remove from the collection.
    public func remove(_ delegate: Delegate) {
        lock.withLock {
            delegates.removeAll {
                $0.value === delegate as AnyObject
            }
        }
    }
    
    /// Performs the given block against each delegate within the collection.
    /// - Parameter block: Block to invoke for each delegate instance.
    public func invoke(_ block: (Delegate) throws -> Void) rethrows {
        try lock.withLock {
            for (index, delegate) in delegates.enumerated() {
                if let delegate = delegate.value as? Delegate {
                    try block(delegate)
                } else {
                    delegates.remove(at: index)
                }
            }
        }
    }
    
    /// Performs the given block for each delegate within the collection, coalescing the results into the returned array.
    /// - Parameter block: Block to invoke for each delegate instance.
    /// - Returns: Resulting array of returned values from the delegates in the collection.
    public func invoke<T>(_ block: (Delegate) throws -> T) rethrows -> [T] {
        try lock.withLock {
            var result = [T]()
            for (index, delegate) in delegates.enumerated() {
                if let delegate = delegate.value as? Delegate {
                    result.append(try block(delegate))
                } else {
                    delegates.remove(at: index)
                }
            }
            return result
        }
    }
}

fileprivate class DelegateCollectionNode<Delegate>: Equatable {
    static func == (lhs: DelegateCollectionNode<Delegate>, rhs: DelegateCollectionNode<Delegate>) -> Bool {
        return lhs.value === rhs.value
    }
    
    weak var value: AnyObject?

    init(value: AnyObject) {
        self.value = value
    }
}

extension RangeReplaceableCollection where Iterator.Element: Equatable {
    @discardableResult
    fileprivate mutating func remove(_ element: Iterator.Element) -> Iterator.Element? {
        guard let index = self.firstIndex(of: element) else {
            return nil
        }
        return self.remove(at: index)
    }
}
