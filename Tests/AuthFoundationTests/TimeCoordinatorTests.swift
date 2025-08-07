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

import Testing
import Foundation

@testable import AuthFoundation
@testable import TestCommon

@Suite("Time Coordination and Date Management", .disabled("Debugging test deadlocks within CI"))
struct TimeCoordinatorTests {
    @Test("Date adjustments with time offset coordination", .mockTimeCoordinator)
    func testDateAdjustments() throws {
        let coordinator = try #require(Date.coordinator as? MockTimeCoordinator)
        let date = Date()
        
        #expect(date == date.coordinated)
        coordinator.offset = 300
        #expect(date != date.coordinated)
        #expect(date.coordinated.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate == 300)
        
        #expect(Date.nowCoordinated > Date())
    }
    
    @Test("Default time coordinator behavior without offsets", .mockTimeCoordinator)
    func testDefaultTimeCoordinator() throws {
        let date = Date()
        
        #expect(date == date.coordinated)
    }
}
