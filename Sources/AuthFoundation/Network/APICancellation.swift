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

extension APIClientCancellable {
    /// Adds the given cancellable task to the cancellable handler.
    /// - Parameter cancellationHandler: Cancellable handler to add this task to.
    public func add(to cancellationHandler: APICancellation) {
        cancellationHandler.add(self)
    }
}

/// Utility class that weakly references one or more ``APIClientCancellable`` operations, and can cancel them as a group.
final public class APICancellation: APIClientCancellable {
    final public class EmptyCancellable: APIClientCancellable {
        final public func cancel() {}
    }

    /// Convenience cancellable object that will never cancel.
    public static let none: APIClientCancellable = EmptyCancellable()

    final private class CancellableTask {
        weak private(set) var task: APIClientCancellable?
        private(set) var block: (() -> Void)?

        private let lock = UnfairLock()

        init(task: APIClientCancellable? = nil, block: (() -> Void)? = nil) {
            self.task = task
            self.block = block
        }

        final func cancel() {
            lock.withLock {
                if let task {
                    task.cancel()
                    self.task = nil
                }
                
                if let block {
                    block()
                    self.block = nil
                }
            }
        }
        
        final func invalidate() {
            lock.withLock {
                task = nil
                block = nil
            }
        }
    }
    
    /// Designated initializer to create a cancellation handler for the given set of tasks.
    /// - Parameter tasks: List of tasks to initialize
    public init(_ tasks: APIClientCancellable...) {
        self.tasks = tasks.map({ .init(task: $0) })
    }
    
    private let lock = UnfairLock()
    private var tasks: [CancellableTask] = []
    
    /// Adds a new cancellable task to the cancellation group.
    /// - Parameter task: Cancellable task to add.
    public func add(_ task: any APIClientCancellable) {
        lock.withLock {
            if let cancellation = task as? APICancellation {
                tasks.append(contentsOf: cancellation.tasks)
            } else {
                tasks.append(.init(task: task))
            }
        }
    }
    
    /// Adds the given block to the cancellable task handler.
    /// - Parameter block: Block to invoke when the task is complete.
    public func add(_ block: @escaping () -> Void) {
        lock.withLock {
            tasks.append(.init(block: block))
        }
    }
    
    /// Cancel all cancellable tasks within this task handler.
    public func cancel() {
        lock.withLock {
            tasks.forEach { $0.cancel() }
            tasks.removeAll()
        }
    }
    
    /// Invalidate all nested tasks without cancelling them.
    public func invalidate() {
        lock.withLock {
            tasks.forEach { $0.invalidate() }
            tasks.removeAll()
        }
    }
}
