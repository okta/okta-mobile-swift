//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class AccountUnlockScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .accountUnlock }
    
    private var signInButton: XCUIElement {
        app.buttons["Sign In"]
    }
    
    private var signUpButton: XCUIElement {
        app.buttons["button.Sign Up"]
    }
    
    private var continueButton: XCUIElement {
        // There're two buttons with the same identifier
        app.buttons.allElementsBoundByIndex.first { $0.identifier == "button.Next" } ?? app.buttons["button.Next"]
    }
    
    private var skipButton: XCUIElement {
        app.buttons["button.Skip"]
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try? scenario.resetMessages(.sms)
        try? scenario.resetMessages(.email)
        try scenario.createUser(groups: [.mfa])
        
        signInButton.tap()
        
        let credentials = try XCTUnwrap(scenario.credentials)
        scenario.lockUser(username: credentials.username)
        
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: "badCredentials")
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try scenario.deleteUser()
    }
    
    // Scenario 11.1.?
    func testUnlockAccountWithEmailLink() throws {
        let credentials = try XCTUnwrap(scenario.credentials)

        let unlockPage = UnlockAccountPage(app: app)
        unlockPage.assert()
        unlockPage.unlock(username: credentials.username, factor: .email)
        
        let code = try scenario.receive(code: .email, magicLink: true)
        
        // Open Safari
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        let _ = safari.wait(for: .runningForeground, timeout: .regular)

        // Copy and paste the URL into the address bar
        UIPasteboard.general.string = code
        safari.textFields.firstMatch.tap()
        safari.textFields.firstMatch.tap()
        safari.menuItems["Paste and Go"].firstMatch.tap()
        
        // Tap the consent button
        safari.buttons["Yes, it's me"].firstMatch.tap()
        XCTAssertTrue(safari.staticTexts["Success! Return to the original tab or window"].waitForExistence(timeout: .regular))
        
        // Switch back to the app, and wait for success
        app.activate()
        XCTAssertTrue(app.staticTexts["oie.selfservice.unlock_user.success.message"].waitForExistence(timeout: .regular))
    }

    // Scenario 11.1.3
    func testUnlockAccountWithEmailOTP() throws {
        let credentials = try XCTUnwrap(scenario.credentials)

        let unlockPage = UnlockAccountPage(app: app)
        unlockPage.assert()
        unlockPage.unlock(username: credentials.username, factor: .email)
        
        let codePage = PasscodeFormPage(app: app, scenario: scenario)
        XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(codePage.passcodeField.exists)
        try codePage.verify(factor: .email)
        
        XCTAssertTrue(app.staticTexts["oie.selfservice.unlock_user.success.message"].waitForExistence(timeout: .regular))
    }

    // Scenario 11.1.4
    func testUnlockAccountWithPhoneOTP() throws {
        let credentials = try XCTUnwrap(scenario.credentials)

        let unlockPage = UnlockAccountPage(app: app)
        unlockPage.assert()
        unlockPage.unlock(username: credentials.username, factor: .sms)
        
        let codePage = PasscodeFormPage(app: app, scenario: scenario)
        XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(codePage.passcodeField.exists)
        try codePage.verify(factor: .sms)
        
        XCTAssertTrue(app.staticTexts["oie.selfservice.unlock_user.success.message"].waitForExistence(timeout: .regular))
    }
}
