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

@preconcurrency import Foundation

public final class CoalescedResult<T: Sendable>: Sendable {
    private let lock = Lock()
    public let queue: DispatchQueue
    
    public init(queue: DispatchQueue = .main) {
        self.queue = queue
    }
    
    public var isActive: Bool {
        get {
            lock.withLock {
                _isActive
            }
        }
    }
    
    public func add(_ completion: @Sendable @escaping (T) -> Void) {
        lock.withLock {
            completionHandlers.append(completion)
        }
    }
    
    public func perform(_ completion: (@Sendable (T) -> Void)?, operation: @Sendable (@Sendable @escaping (T) -> Void) -> Void) {
        lock.withLock {
            if let completion = completion {
                completionHandlers.append(completion)
            }
            
            guard !_isActive else {
                return
            }
            
            _isActive = true
            
            operation() { result in
                self.queue.async(flags: .barrier) {
                    let group = DispatchGroup()
                    
                    self.completionHandlers.forEach { block in
                        self.queue.async(group: group) {
                            block(result)
                        }
                    }
                    
                    group.notify(queue: self.queue) {
                        self.lock.withLock {
                            self._isActive = false
                        }
                    }
                }
            }
        }
    }

    nonisolated(unsafe) private var completionHandlers: [@Sendable (T) -> Void] = []
    nonisolated(unsafe) private var _isActive = false
}
