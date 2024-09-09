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

import XCTest
@testable import AuthFoundation
@testable import TestCommon

class APICancellationTests: XCTestCase {
    class Task: APIClientCancellable {
        private(set) var isCancelled = false
        let function: () -> Void
        
        init(_ function: @escaping () -> Void) {
            self.function = function
        }
        
        func cancel() {
            isCancelled = true
        }
        
        func perform() {
            guard !isCancelled else { return }
            function()
        }
    }
    
    func createTasks(_ block: @escaping () -> Void) -> (APICancellation, [Task]) {
        let cancellable = APICancellation()
        
        var tasks = [Task]()
        for _ in 0..<10 {
            let task = Task(block)
            cancellable.add(task)
            tasks.append(task)
        }
        
        return (cancellable, tasks)
    }
    
    func testCancellableTasks() throws {
        var counter = 0
        let (cancellable, tasks) = createTasks {
            counter += 1
        }
        
        tasks[0].perform()
        tasks[1].perform()
        cancellable.cancel()
        tasks.forEach({ $0.perform() })
        
        XCTAssertEqual(counter, 2)
    }

    func testNestedCancellableTasks() throws {
        var counter = 0
        let (outerCancellable, outerTasks) = createTasks {
            counter += 1
        }
        outerTasks[1].perform()

        let (innerCancellable, innerTasks) = createTasks {
            counter += 1
        }
        innerCancellable.add(to: outerCancellable)
        
        innerTasks[0].perform()
        outerCancellable.cancel()

        innerTasks.forEach({ $0.perform() })
        outerTasks.forEach({ $0.perform() })
        
        XCTAssertEqual(counter, 2)
    }
}
