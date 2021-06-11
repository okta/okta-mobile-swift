//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

final class ResetPasswordScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }

    override static func setUp() {
        super.setUp()
        
        do {
            try scenario.createUser()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testResetSuccessful() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        XCTAssertTrue(signInPage.initialSignInButton.waitForExistence(timeout: .regular))
        signInPage.initialSignInButton.tap()

        XCTAssertTrue(signInPage.recoveryButton.waitForExistence(timeout: .regular))
        signInPage.recoveryButton.tap()
        
        let emailRecoveryPage = UsernameRecoveryFormPage(app: app)
        XCTAssertTrue(emailRecoveryPage.usernameLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(emailRecoveryPage.usernameField.exists)
        XCTAssertTrue(emailRecoveryPage.continueButton.exists)
        
        if !emailRecoveryPage.usernameField.isFocused {
            emailRecoveryPage.usernameField.tap()
        }
        
        emailRecoveryPage.usernameField.typeText(credentials.username)
        emailRecoveryPage.continueButton.tap()
        
        
        let methodPage = RecoveryMethodPage(app: app)
        XCTAssertTrue(methodPage.emailButton.waitForExistence(timeout: .regular))
        XCTAssertTrue(methodPage.continueButton.waitForExistence(timeout: .regular))
        
        methodPage.emailButton.tap()
        methodPage.continueButton.tap()
        
        let codePage = PasscodeFormPage(app: app)
        XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(codePage.passcodeField.exists)
        XCTAssertTrue(codePage.resendButton.exists)
        XCTAssertTrue(codePage.continueButton.exists)
        
        let emailCode = try scenario.receive(code: .email)

        if !codePage.passcodeField.isFocused {
            codePage.passcodeField.tap()
        }
        
        codePage.passcodeField.typeText(emailCode)
        codePage.continueButton.tap()
        
        let passwordPage = NewPasswordFormPage(app: app)
        XCTAssertTrue(passwordPage.passwordField.waitForExistence(timeout: .regular))
        XCTAssertTrue(passwordPage.passwordLabel.exists)
        XCTAssertTrue(passwordPage.continueButton.exists)
        
        if !passwordPage.passwordField.isFocused {
            passwordPage.passwordField.tap()
        }
        
        passwordPage.passwordField.typeText("Abcd123\(Int.random(in: 1...1000))")
        
        passwordPage.continueButton.tap()
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func testResetWithIncorrectUsername() throws {
        let signInPage = SignInFormPage(app: app)
        signInPage.initialSignInButton.tap()
        
        XCTAssertTrue(signInPage.recoveryButton.waitForExistence(timeout: .regular))
        signInPage.recoveryButton.tap()
        
        let emailRecoveryPage = UsernameRecoveryFormPage(app: app)
        XCTAssertTrue(emailRecoveryPage.usernameLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(emailRecoveryPage.usernameField.exists)
        XCTAssertTrue(emailRecoveryPage.continueButton.exists)
        
        if !emailRecoveryPage.usernameField.isFocused {
            emailRecoveryPage.usernameField.tap()
        }
        
        let incorrectUsername = "incorrect.username"
        emailRecoveryPage.usernameField.typeText(incorrectUsername)
        emailRecoveryPage.continueButton.tap()
        
        XCTAssertTrue(app.staticTexts["There is no account with the Username \(incorrectUsername)."].waitForExistence(timeout: .regular))
    }
}
