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

import XCTest
@testable import AuthFoundation

fileprivate actor CoalescedResultCounter {
    var indexes = [Int]()
    var invokedCount = 0
    
    func add(_ index: Int) {
        indexes.append(index)
    }
    
    func invoke() {
        invokedCount += 1
    }
}

final class CoalescedResultTests: XCTestCase {
    struct Item: Equatable {
        static func == (lhs: CoalescedResultTests.Item, rhs: CoalescedResultTests.Item) -> Bool {
            lhs.result == rhs.result && lhs.index == rhs.index
        }
        
        let result: String
        let index: Int
    }
    
    func testMultipleResults() async throws {
        let coalesce = CoalescedResult<String>()
        let counter = CoalescedResultCounter()
        
        try await withThrowingTaskGroup(of: String.self) { group in
            for index in 1...5 {
                group.addTask {
                    let result = try await coalesce.perform {
                        await counter.invoke()
                        return "Success!"
                    }
                    await counter.add(index)
                    return result
                }
            }
            
            for try await result in group {
                XCTAssertEqual(result, "Success!")
            }
        }
        
        let indexes = await counter.indexes
        let invokedCount = await counter.invokedCount
        XCTAssertEqual(indexes.sorted(), [1, 2, 3, 4, 5])
        XCTAssertEqual(invokedCount, 1)
    }
}
