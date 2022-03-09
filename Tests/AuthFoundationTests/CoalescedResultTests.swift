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
        
        var results = [Item]()
        
        for index in 1...5 {
            coalesce.add { result in
                results.append(Item(result: result, index: index))
            }
        }
        
        coalesce.start { completion in
            completion("Success!")
        }
        
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results, [
            Item(result: "Success!", index: 1),
            Item(result: "Success!", index: 2),
            Item(result: "Success!", index: 3),
            Item(result: "Success!", index: 4),
            Item(result: "Success!", index: 5)
        ])
    }
}
