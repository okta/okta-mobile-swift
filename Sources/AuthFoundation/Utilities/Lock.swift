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

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

#if swift(<6.0)
extension UnsafeMutablePointer<Lock.LockType>: @unchecked Sendable {}
#endif

// **Note:** It would be preferable to use OSAllocatedUnfairLock for this, but this would mean dropping support for older OS versions. While this approach is safe, OSAllocatedUnfairLock provides more features we might need in the future.
//
// If the minimum supported version of this SDK is to increase in the future, this class should be removed and replaced with OSAllocatedUnfairLock.
@_documentation(visibility: private)
public final class Lock: NSLocking, Sendable {
    #if canImport(Darwin)
    fileprivate typealias LockType = os_unfair_lock
    #elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
    fileprivate typealias LockType = pthread_mutex_t
    #else
    #error("Unsupported platform")
    #endif

    nonisolated(unsafe) private let _lock: UnsafeMutablePointer<LockType> = {
        let result = UnsafeMutablePointer<LockType>.allocate(capacity: 1)

        #if canImport(Darwin)
        result.initialize(to: os_unfair_lock())
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        let status = pthread_mutex_init(result, nil)
        precondition(status == 0, "pthread_mutex_init failed")
        #else
        #error("Unsupported platform")
        #endif
        
        return result
    }()
    
    public init() {}

    deinit {
        #if canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        let status = pthread_mutex_destroy(_lock)
        precondition(status == 0, "pthread_mutex_destroy failed")
        #endif
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
    
    public func lock() {
        #if canImport(Darwin)
        os_unfair_lock_lock(_lock)
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        let status = pthread_mutex_lock(_lock)
        precondition(status == 0, "pthread_mutex_lock failed")
        #else
        #error("Unsupported platform")
        #endif
    }

    public func tryLock() -> Bool {
        #if canImport(Darwin)
        return os_unfair_lock_trylock(_lock)
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        return pthread_mutex_trylock(_lock) == 0
        #else
        #error("Unsupported platform")
        #endif
    }

    public func unlock() {
        #if canImport(Darwin)
        os_unfair_lock_unlock(_lock)
        #elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
        let status = pthread_mutex_unlock(_lock)
        precondition(status == 0, "pthread_mutex_unlock failed")
        #else
        #error("Unsupported platform")
        #endif
    }

    #if !canImport(Darwin)
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }
    #endif
}