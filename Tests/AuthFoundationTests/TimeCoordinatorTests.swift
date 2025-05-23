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
import TestCommon

class MockTimeCoordinator: @unchecked Sendable, TimeCoordinator {
    @LockedValue var offset: TimeInterval = 0.0

    var now: Date {
        Date(timeIntervalSinceNow: offset)
    }
    
    func date(from date: Date) -> Date {
        date.addingTimeInterval(offset)
    }
}

final class TimeCoordinatorTests: XCTestCase {
    var coordinator: MockTimeCoordinator!
    
    override func setUpWithError() throws {
        coordinator = MockTimeCoordinator()
        Date.coordinator = coordinator
    }
    
    override func tearDownWithError() throws {
        DefaultTimeCoordinator.resetToDefault()
        coordinator = nil
    }
    
    func testDateAdjustments() {
        let date = Date()
        
        XCTAssertEqual(date, date.coordinated)
        coordinator.offset = 300
        XCTAssertNotEqual(date, date.coordinated)
        XCTAssertEqual(date.coordinated.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate, 300)
        
        XCTAssertGreaterThan(Date.nowCoordinated, Date())
    }
    
    func testDefaultTimeCoordinator() {
        let date = Date()
        
        XCTAssertEqual(date, date.coordinated)
    }
}
