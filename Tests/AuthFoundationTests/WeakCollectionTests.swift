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

final class WeakCollectionTests: XCTestCase {
    class Thing: Equatable, Hashable {
        let value: String
        init(_ value: String) {
            self.value = value
        }

        static func == (lhs: WeakCollectionTests.Thing, rhs: WeakCollectionTests.Thing) -> Bool {
            lhs.value == rhs.value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
    }
    
    class Parent {
        @WeakCollection
        var things: [Thing?] = []
    }
    
    func testNilObject() {
        let weak = Weak<Thing>(nil)
        XCTAssertNil(weak)
    }
    
    func testWeakObject() {
        let thing1 = Thing("Thing 1")
        var weak = Weak<Thing>(thing1)
        
        XCTAssertEqual(weak?.wrappedValue?.value, "Thing 1")
        
        do {
            let value = Thing("Thing 2")
            weak?.wrappedValue = value
            XCTAssertEqual(weak?.wrappedValue?.value, "Thing 2")
        }

        XCTAssertNil(weak?.wrappedValue)
    }
    
    func testWeakCollection() {
        var collection = WeakCollection<Array, Thing>(wrappedValue: [])
        
        XCTAssertEqual(collection.wrappedValue.count, 0)
        
        do {
            let value = Thing("Test")
            collection.wrappedValue.append(value)
            XCTAssertEqual(collection.wrappedValue.count, 1)
        }
        
        XCTAssertEqual(collection.wrappedValue.count, 0)
    }
    
    func testPropertyWrapper() {
        let parent = Parent()
        
        XCTAssertEqual(parent.things.count, 0)
        
        do {
            let thing1 = Thing("Thing 1")
            parent.things.append(thing1)
            XCTAssertEqual(parent.things.count, 1)
            XCTAssertEqual(parent.things, [thing1])
        }
        
        XCTAssertEqual(parent.things.count, 0)
    }
}
