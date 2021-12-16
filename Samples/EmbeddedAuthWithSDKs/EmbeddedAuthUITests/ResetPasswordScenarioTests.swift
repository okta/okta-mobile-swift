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

final class ResetPasswordScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try scenario.createUser()

        XCTAssertTrue(initialSignInButton.waitForExistence(timeout: .regular))
        initialSignInButton.tap()
    }
    
    func test_Reset_Password() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        
        test("GIVEN Mary navigates to the Self Service Registration View") {
            let emailRecoveryPage = UsernameRecoveryFormPage(app: app)
            let signInPage = SignInFormPage(app: app)
            
            XCTAssertTrue(signInPage.recoveryButton.waitForExistence(timeout: .regular))
            signInPage.recoveryButton.tap()
            
            XCTAssertTrue(emailRecoveryPage.usernameLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(emailRecoveryPage.usernameField.exists)
            XCTAssertTrue(emailRecoveryPage.continueButton.exists)
            
            test("WHEN she inputs her correct Username") {
                if !emailRecoveryPage.usernameField.isFocused {
                    emailRecoveryPage.usernameField.tap()
                }
                
                emailRecoveryPage.usernameField.typeText(credentials.username)
            }
            
            test("AND she submits the Username form") {
                emailRecoveryPage.continueButton.tap()
            }
        }
        
        test("THEN she sees recovery option form") {
            let methodPage = RecoveryMethodPage(app: app)
            XCTAssertTrue(methodPage.emailButton.waitForExistence(timeout: .regular))
            XCTAssertTrue(methodPage.continueButton.waitForExistence(timeout: .regular))
            
            test("AND she selects Email option") {
                methodPage.emailButton.tap()
            }
            
            test("THEN she submits the choice") {
                methodPage.continueButton.tap()
            }
        }
        
        try test("THEN she sees a page to input her code") {
            let codePage = PasscodeFormPage(app: app, scenario: scenario)
            XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(codePage.passcodeField.exists)
            XCTAssertTrue(codePage.resendButton.exists)
            XCTAssertTrue(codePage.continueButton.exists)
            
            let emailCode = try receive(code: .email)
            
            test("WHEN she fills in the correct code") {
                if !codePage.passcodeField.isFocused {
                    codePage.passcodeField.tap()
                }
                
                codePage.passcodeField.typeText(emailCode)
                codePage.continueButton.tap()
            }
        }
        
        test("THEN she sees a page to set her password") {
            let passwordPage = NewPasswordFormPage(app: app)
            XCTAssertTrue(passwordPage.passwordField.waitForExistence(timeout: .regular))
            XCTAssertTrue(passwordPage.passwordLabel.exists)
            XCTAssertTrue(passwordPage.continueButton.exists)
            
            test("WHEN she fills a password that fits within the password policy") {
                if !passwordPage.passwordField.isFocused {
                    passwordPage.passwordField.tap()
                }
                
                passwordPage.passwordField.typeText("Abcd123\(Int.random(in: 1...1000))")
            }
            
            test("AND she submits the form") {
                passwordPage.continueButton.tap()
            }
        }
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func testResetWithIncorrectUsername() throws {
        test("GIVEN Mary navigates to the Self Service Password Reset View") {
            let signInPage = SignInFormPage(app: app)
            
            test("WHEN she selects 'Forgot Password'") {
                XCTAssertTrue(signInPage.recoveryButton.waitForExistence(timeout: .regular))
                signInPage.recoveryButton.tap()
            }
        }
        
        let incorrectUsername = "incorrect.username"
        
        test("THEN she sees the Password Recovery Page") {
            let emailRecoveryPage = UsernameRecoveryFormPage(app: app)
            XCTAssertTrue(emailRecoveryPage.usernameLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(emailRecoveryPage.usernameField.exists)
            XCTAssertTrue(emailRecoveryPage.continueButton.exists)
            
            test("WHEN she inputs an Email that doesn't exist") {
                if !emailRecoveryPage.usernameField.isFocused {
                    emailRecoveryPage.usernameField.tap()
                }
                
                emailRecoveryPage.usernameField.typeText(incorrectUsername)
            }
            
            test("AND she submits the form") {
                emailRecoveryPage.continueButton.tap()
            }
        }
        
        test("THEN she sees an error message") {
            XCTAssertTrue(app.staticTexts["There is no account with the Username \(incorrectUsername)."].waitForExistence(timeout: .regular))
        }
    }
}
