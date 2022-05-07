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
import XCTest

extension TimeInterval {
    static let standard: TimeInterval = 3
    static let short: TimeInterval = 1
    static let long: TimeInterval = 5
}

extension XCTestCase {
    func save(screenshot label: String) {
        let attachment = XCTAttachment(screenshot: XCUIApplication().screenshot())
        attachment.name = label
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}

extension XCUIElement {
    var isOn: Bool? {
        return (self.value as? String).map { $0 == "1" }
    }

    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let timeStart = Date().timeIntervalSince1970
        
        while Date().timeIntervalSince1970 <= (timeStart + timeout) {
            if !exists {
                return true
            }
        }
        
        return false
    }
}

extension XCUIElementQuery {
    func cell(containing label: String) -> XCUIElement? {
        for cell in tables.cells.allElementsBoundByIndex {
            if cell.staticTexts[label].exists {
                return cell
            }
        }
        return nil
    }
}

