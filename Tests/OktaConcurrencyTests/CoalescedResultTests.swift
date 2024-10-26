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
@testable import OktaConcurrency
@testable import TestCommon

final class CoalescedResultTests: XCTestCase {
    struct Item: Equatable {
        static func == (lhs: CoalescedResultTests.Item, rhs: CoalescedResultTests.Item) -> Bool {
            lhs.result == rhs.result && lhs.index == rhs.index
        }
        
        let result: String
        let index: Int
    }
    
    func testMultipleResults() throws {
        let coalesce = CoalescedResult<String>()
        
        let queues: [DispatchQueue] = (0..<5).map { queueNumber in
            DispatchQueue(label: "Async queue \(queueNumber)")
        }

        nonisolated(unsafe) var results = [Item]()
        nonisolated(unsafe) var operationCount = 0
        let group = DispatchGroup()
        
        for index in 0..<10 {
            group.enter()
            let queue = try XCTUnwrap(queues.randomElement())
            queue.async {
                coalesce.perform { value in
                    results.append(Item(result: value, index: index))
                    group.leave()
                } operation: { finish in
                    operationCount += 1
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                        finish("Success from \(index)!")
                    }
                }
            }
        }
        
        let expect = expectation(description: "Completion")
        group.notify(queue: .main) {
            expect.fulfill()
        }
        waitForExpectations(timeout: .short)
        
        XCTAssertEqual(operationCount, 1)
        XCTAssertEqual(results.count, 10)
        XCTAssertEqual(results.sorted(by: { $0.index < $1.index }), [
            Item(result: "Success from 0!", index: 0),
            Item(result: "Success from 0!", index: 1),
            Item(result: "Success from 0!", index: 2),
            Item(result: "Success from 0!", index: 3),
            Item(result: "Success from 0!", index: 4),
            Item(result: "Success from 0!", index: 5),
            Item(result: "Success from 0!", index: 6),
            Item(result: "Success from 0!", index: 7),
            Item(result: "Success from 0!", index: 8),
            Item(result: "Success from 0!", index: 9),
        ])
    }
}
