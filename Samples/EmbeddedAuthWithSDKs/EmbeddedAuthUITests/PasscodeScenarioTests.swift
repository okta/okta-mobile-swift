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


func test<T>(_ description: String, block: () throws -> T) rethrows -> T {
    try XCTContext.runActivity(named: description, block: { _ in try block() })
}

final class PasscodeScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try scenario.createUser()
    }
    
    func test_Login_with_a_Password() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)

        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func test_Incorrect_Username() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        
        let username = "incorrect.username@okta.com"
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: username, password: credentials.password)
        
        test("THEN she should see a message on the Login form") {
            let incorrectUsernameAlert = app.tables.staticTexts["There is no account with the Username \(username)."]
            XCTAssertTrue(incorrectUsernameAlert.waitForExistence(timeout: .regular))
        }
    }
    
    func test_Incorrect_Password() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: "InvalidPassword")
        
        test("THEN she should see the message") {
            let incorrectPasswordLabel = app.tables.staticTexts["Authentication failed"]
            XCTAssertTrue(incorrectPasswordLabel.waitForExistence(timeout: .regular))
        }
    }
    
    func test_Forgot_Password_Redirection() throws {
        let signInPage = SignInFormPage(app: app)
        
        test("GIVEN Mary navigates to the Basic Login View") {
            XCTAssertTrue(signInPage.initialSignInButton.waitForExistence(timeout: .regular))
            signInPage.initialSignInButton.tap()
        }
        
        test("WHEN she clicks on the Forgot Password button") {
            XCTAssertTrue(signInPage.recoveryButton.waitForExistence(timeout: .regular))
            signInPage.recoveryButton.tap()
        }
        
        
        test("THEN she is redirected to the Self Service Password Reset View") {
            let emailRecoveryPage = UsernameRecoveryFormPage(app: app)
            XCTAssertTrue(emailRecoveryPage.usernameLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(emailRecoveryPage.usernameField.exists)
            XCTAssertTrue(emailRecoveryPage.continueButton.exists)
        }
    }
}

