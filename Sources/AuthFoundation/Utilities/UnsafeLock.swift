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

// **Note:** It would be preferable to use OSAllocatedUnfairLock for this, but this would mean dropping support for older OS versions. While this approach is safe, OSAllocatedUnfairLock provides more features we might need in the future.
//
// If the minimum supported version of this SDK is to increase in the future, this class should be removed and replaced with OSAllocatedUnfairLock.
final class UnfairLock: NSLocking {
    private let _lock: UnsafeMutablePointer<os_unfair_lock> = {
        let result = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        result.initialize(to: os_unfair_lock())
        return result
    }()
    
    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
    
    func lock() {
        os_unfair_lock_lock(_lock)
    }

    func tryLock() -> Bool {
        os_unfair_lock_trylock(_lock)
    }

    func unlock() {
        os_unfair_lock_unlock(_lock)
    }
}
