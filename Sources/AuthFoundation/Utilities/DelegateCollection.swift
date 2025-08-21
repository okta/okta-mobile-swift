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

#if !COCOAPODS
import CommonSupport
#endif

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

public final class DelegateCollection<D>: @unchecked Sendable {
    @WeakCollection private var delegates: [(any AnyObject)?]
    private let lock = Lock()

    public init() {
        delegates = []
    }
}

extension DelegateCollection {
    /// Adds the given argument as a delegate.
    /// - Parameter delegate: Delegate to add to the collection.
    public func add(_ delegate: D) {
        lock.withLock {
            delegates.append(delegate as AnyObject)
        }
    }
    
    /// Removes the given argument from the collection of delegates.
    /// - Parameter delegate: Delegate to remove from the collection.
    public func remove(_ delegate: D) {
        let delegateObject = delegate as AnyObject
        lock.withLock {
            delegates.removeAll { object in
                object === delegateObject
            }
        }
    }
    
    /// Performs the given block against each delegate within the collection.
    /// - Parameter block: Block to invoke for each delegate instance.
    public func invoke(_ block: (D) -> Void) {
        let allDelegates = lock.withLock { _delegates.wrappedValue.compactMap({ $0 }) }
        allDelegates.forEach {
            guard let delegate = $0 as? D else { return }
            block(delegate)
        }
    }
    
    /// Performs the given block for each delegate within the collection, coalescing the results into the returned array.
    /// - Parameter block: Block to invoke for each delegate in the collection.
    /// - Returns: Resulting array of returned values from the delegates in the collection.
    public func call<T>(_ block: (D) -> T) -> [T] {
        let allDelegates = lock.withLock { _delegates.wrappedValue.compactMap({ $0 }) }
        return allDelegates.compactMap {
            guard let delegate = $0 as? D else { return nil }
            return block(delegate)
        }
    }
}
