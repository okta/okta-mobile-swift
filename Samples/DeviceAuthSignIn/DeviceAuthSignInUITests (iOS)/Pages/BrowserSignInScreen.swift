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

class BrowserSignInScreen: Screen {
    let app = XCUIApplication()
    let testCase: XCTestCase

    lazy var urlPromptLabel = app.staticTexts["url_prompt_label"]
    lazy var codeLabel = app.staticTexts["code_label"]
    lazy var openBrowserButton = app.buttons["open_browser_button"]

    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
        
    func isVisible(timeout: TimeInterval = 3) {
        XCTAssertTrue(app.staticTexts["Activate your device"].waitForExistence(timeout: timeout))
    }
    
    func verifyActivationCode(_ code: String) {
        XCTAssertTrue(app.webViews.textFields.firstMatch.waitForExistence(timeout: .long))
        
        let screenCode = app.webViews.textFields.firstMatch.value as? String
        
        XCTAssertEqual(code.replacingOccurrences(of: " ", with: ""),
                       screenCode)
        app.webViews.buttons["Next"].tap()
    }

    func login(username: String, password: String) {
        XCTAssertTrue(app.webViews
            .staticTexts["Sign In"]
            .firstMatch
            .waitForExistence(timeout: .standard))

        let usernameField = app.webViews.textFields.element(boundBy: 0)
        if !usernameField.hasFocus {
            usernameField.tap()
        }
        
        usernameField.typeText(username)

        let passwordField = app.webViews.secureTextFields.element(boundBy: 0)
        if !passwordField.hasFocus {
            passwordField.tap()
        }
        
        passwordField.typeText(password)
        
        app.webViews.buttons["Sign in"].tap()
    }
    
    func waitForAuthorization() {
        XCTAssertTrue(app.webViews.staticTexts["Device activated"].waitForExistence(timeout: .standard))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForNonExistence(timeout: .short))
    }
}
