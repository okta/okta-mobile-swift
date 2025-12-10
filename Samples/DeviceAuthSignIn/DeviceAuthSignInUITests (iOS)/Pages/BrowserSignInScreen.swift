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

class BrowserSignInScreen: Screen, WebLogin {
    let app = XCUIApplication()
    let testCase: XCTestCase

    lazy var urlPromptLabel = app.staticTexts["url_prompt_label"]
    lazy var codeLabel = app.staticTexts["code_label"]
    lazy var openBrowserButton = app.buttons["open_browser_button"]
    lazy var ephemeralSwitch = app.switches["ephemeral_switch"]
    lazy var signInButton = app.buttons["sign_in_button"]

    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
        
    func isVisible(timeout: TimeInterval = .veryLong) {
        XCTAssertTrue(app.staticTexts["Activate your device"].waitForExistence(timeout: timeout))
        testCase.save(screenshot: "Activate your device")
    }
    
    var isEphemeral: Bool {
        true
    }
    
    func verifyActivationCode(_ code: String) {
        XCTAssertTrue(app.webViews.textFields.firstMatch.waitForExistence(timeout: .long))
        
        let screenCode = app.webViews.textFields.firstMatch.value as? String
        
        XCTAssertEqual(code.replacingOccurrences(of: " ", with: ""),
                       screenCode)
        testCase.save(screenshot: "Verify activation code")
        app.webViews.buttons["Next"].tap()
    }
}
