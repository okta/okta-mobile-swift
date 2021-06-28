/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest

class ResetTransactionScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try scenario.createUser()
    }

    func DISABLED_testCancelMFARemediation() throws {
        let credentials = try XCTUnwrap(scenario.credentials)

        let app = XCUIApplication()
        app.buttons["Sign In"].tap()

        // Username
        XCTAssertTrue(app.staticTexts["identifier.label"].waitForExistence(timeout: .regular))
        XCTAssertEqual(app.staticTexts["identifier.label"].label, "Username")
        XCTAssertEqual(app.staticTexts["rememberMe.label"].label, "Remember this device")
        
        let usernameField = app.textFields["identifier.field"]
        XCTAssertEqual(usernameField.value as? String, "")
        if !usernameField.isFocused {
            usernameField.tap()
        }
        usernameField.typeText(credentials.username)

        app.buttons["Next"].tap()
        
        // Select remediation type
        XCTAssertTrue(app.tables.staticTexts["authenticator.label"].waitForExistence(timeout: .regular))
        app.tables.staticTexts["Password"].tap()
        app.buttons["Choose"].tap()

        // Password
        let passwordField = app.secureTextFields["passcode.field"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: .regular))
        XCTAssertEqual(app.staticTexts["passcode.label"].label, "Password")
        
        XCTAssertEqual(passwordField.value as? String, "")
        if !passwordField.isFocused {
            passwordField.tap()
        }
        passwordField.typeText(credentials.password)

        app.buttons["Continue"].tap()
        
        // Cancel remediation
        XCTAssertTrue(app.tables.staticTexts["authenticator.label"].waitForExistence(timeout: .regular))
        app.buttons["Restart"].tap()

        // Back to the Username screen
        XCTAssertTrue(app.staticTexts["identifier.label"].waitForExistence(timeout: .regular))
        XCTAssertEqual(app.staticTexts["identifier.label"].label, "Username")
        XCTAssertEqual(app.staticTexts["rememberMe.label"].label, "Remember this device")
    }
}
