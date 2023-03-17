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

import AuthFoundation
import XCTest

class ThreadSafeTests: XCTestCase {
    @ThreadSafe
    var primitiveValue: Int = 0
    
    var readQueue: DispatchQueue!
    var queues: [DispatchQueue]!
    
    override func setUpWithError() throws {
        queues = [DispatchQueue]()
        for index in 0...3 {
            queues.append(DispatchQueue(label: "\(name)[\(index)]"))
        }
        readQueue = DispatchQueue(label: "\(name).read")
        
        primitiveValue = 0
    }
    
    func testPrimitiveUpdates() {
        let group = DispatchGroup()
        
        func add() {
            primitiveValue += 1
        }
        
        for queue in queues {
            group.enter()
            queue.async {
                for _ in 0..<100 {
                    add()
                }
                group.leave()
            }
        }
        
        group.enter()
        readQueue.async {
            for _ in 0..<400 {
                _ = self.primitiveValue
            }
            
            group.leave()
        }
        
        let wait = expectation(description: "Wait for writes to finish")
        group.notify(queue: .main) {
            wait.fulfill()
        }
        waitForExpectations(timeout: 5)
        
        XCTAssertEqual(primitiveValue, queues.count * 100)
    }
}
