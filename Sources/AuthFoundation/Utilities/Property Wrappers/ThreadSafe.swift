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

/// Property wrapper that implements thread-safe locking for wrapped property values.
///
/// > Important: This is only useful for primitive value types, and will produce unexpected results when used with collection value types, such as dictionaries or arrays.
@propertyWrapper
public struct ThreadSafe<T> {
    private var value: T
    private let lock = NSLock()

    public var wrappedValue: T {
        get { value }
        
        _modify {
            lock.lock()
            var mutated: T = value

            defer {
                value = mutated
                lock.unlock()
            }

            yield &mutated
        }
    }

    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
