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
import Testing

@testable import AuthFoundation
import TestCommon

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

@Suite("Coalesced result async tests")
struct CoalescedResultTests {
    struct Item: Equatable {
        static func == (lhs: CoalescedResultTests.Item, rhs: CoalescedResultTests.Item) -> Bool {
            lhs.result == rhs.result && lhs.index == rhs.index
        }

        let result: String
        let index: Int
    }

    @Test("Multiple results")
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
                #expect(result == "Success!")
            }
        }

        let indexes = await counter.indexes
        let invokedCount = await counter.invokedCount
        #expect(indexes.sorted() == [1, 2, 3, 4, 5])
        #expect(invokedCount == 1)
    }

    @Test("Concurrently performed under high load")
    func testPerformUnderHighLoad() async throws {
        let processorCount = ProcessInfo.processInfo.activeProcessorCount
        let parallelRequests = processorCount * 100

        let counter = CoalescedResultCounter()
        let coalescedResult = CoalescedResult<Bool>()
        #expect(coalescedResult.value == nil, "value should be initially nil")

        let group = DispatchGroup()
        DispatchQueue.concurrentPerform(iterations: parallelRequests) { iteration in
            group.enter()
            Task.detached {
                let result = try await coalescedResult.perform {
                    try await Task.sleep(delay: 0.001)
                    await counter.add(iteration)
                    return true
                }
                #expect(result, "Returned value should be now be true")
                await counter.invoke()
                group.leave()
            }
        }
        
        try await confirmClosure("Wait for the operations to complete", timeout: .long)
        { (confirm: @escaping @Sendable (Result<Void, any Error>) -> Void) in
            group.notify(queue: .main) {
                confirm(.success(()))
            }
        }
        
        #expect(coalescedResult.value ?? false, "value should be now be true")
        #expect(await counter.invokedCount == parallelRequests)
    }

    @Test("Nonisolated property deadlock under high load", .disabled("Debugging test deadlocks within CI"))
    func testNonisolatedPropertyDeadlockUnderHighLoad() async throws {
        let processorCount = ProcessInfo.processInfo.activeProcessorCount
        let parallelRequests = processorCount * 100

        let counter = CoalescedResultCounter()
        let coalescedResult = CoalescedResult<Bool>()
        #expect(coalescedResult.value == nil, "value should be initially nil")

        let group = DispatchGroup()
        DispatchQueue.concurrentPerform(iterations: parallelRequests) { _ in
            group.enter()
            let isActive = coalescedResult.isActive
            #expect(!isActive, "isActive should initially be false")

            let value = coalescedResult.value
            #expect(value == nil, "value should initially be nil")

            Task {
                await counter.invoke()
                group.leave()
            }
        }

        try await confirmation("Wait for the operations to complete", timeout: .long) { confirm in
            group.notify(queue: .main) {
                confirm()
            }
        }
        
        #expect(await counter.invokedCount == parallelRequests)
    }
}
