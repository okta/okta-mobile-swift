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

public protocol UsesDelegateCollection {
    associatedtype Delegate
    func add(delegate: Delegate)
    func remove(delegate: Delegate)

    var delegateCollection: DelegateCollection<Delegate> { get }
}

extension UsesDelegateCollection {
    public func add(delegate: Delegate) { delegateCollection.add(delegate) }
    public func remove(delegate: Delegate) { delegateCollection.remove(delegate) }
}

public final class DelegateCollection<D> {
    @WeakCollection private var delegates: [AnyObject?]
    
    public init() {
        delegates = []
    }
}

extension DelegateCollection {
    public func add(_ delegate: D) {
        delegates.append(delegate as AnyObject)
    }
    
    public func remove(_ delegate: D) {
        let delegateObject = delegate as AnyObject
        delegates.removeAll { object in
            object === delegateObject
        }
    }
    
    public func invoke(_ block: (D) -> Void) {
        delegates.forEach {
            guard let delegate = $0 as? D else { return }
            block(delegate)
        }
    }
    
    public func call<T>(_ block: (D) -> T) -> [T] {
          delegates.compactMap {
              guard let delegate = $0 as? D else { return nil }
              return block(delegate)
          }
      }
}
