/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

class SelfServiceRegistrationScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .selfServiceRegistration }
    
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
        try scenario.deleteUser()
    }
    
    override func tearDownWithError() throws {
        try super.setUpWithError()
        try scenario.deleteUser()
    }

    func testSignUpWithPasswordEmail() throws {
        let credentials = try XCTUnwrap(scenario.credentials)

        signInButton.tap()

        try passEmailFactor(email: credentials.username)
        
        XCTAssertTrue(skipButton.waitForExistence(timeout: .regular))
        skipButton.tap()
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func testSignUpWithPasswordEmailPhone() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let phoneNumber = try XCTUnwrap(scenario.profile?.phoneNumber)

        signInButton.tap()

        try passEmailAndPhoneFactors(email: credentials.username, phone: phoneNumber)
        
        let usernameLabel = app.tables.cells["username"]
        XCTAssertTrue(usernameLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(usernameLabel.staticTexts[credentials.username].exists)
    }
    
    func testSignUpWithIncorrectEmail() throws {
        signInButton.tap()
        XCTAssertTrue(signUpButton.waitForExistence(timeout: .regular))
        signUpButton.tap()
        
        try fillInInitialPage(email: "invalid@email")
        
        XCTAssertTrue(app.tables.staticTexts["'Email' must be in the form of an email address"].waitForExistence(timeout: .regular))
        XCTAssertTrue(app.tables.staticTexts["Provided value for property 'Email' does not match required pattern"].waitForExistence(timeout: .minimal))
    }
    
    func testSignUpWithIncorrectPhone() throws {
        let credentials = try XCTUnwrap(scenario.credentials)

        signInButton.tap()
        
        try passEmailFactor(email: credentials.username)
        
        fillInPhonePage(phone: "1230871234567")
        
        XCTAssertTrue(app.tables.staticTexts["Unable to initiate factor enrollment: Invalid Phone Number."].waitForExistence(timeout: .regular))
    }
    
    private func passEmailAndPhoneFactors(email: String, phone: String) throws {
        try passEmailFactor(email: email)
        
        fillInPhonePage(phone: phone)

        let phonePasscodePage = PasscodeFormPage(app: app)
        XCTAssertTrue(phonePasscodePage.passcodeLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(phonePasscodePage.passcodeField.exists)
        XCTAssertTrue(phonePasscodePage.continueButton.exists)
        
        if !phonePasscodePage.passcodeField.isFocused {
            phonePasscodePage.passcodeField.tap()
        }
        
        let smsCode = try receive(code: .sms)
        phonePasscodePage.passcodeField.typeText(smsCode)
        
        phonePasscodePage.continueButton.tap()
    }
    
    private func passEmailFactor(email: String) throws {
        XCTAssertTrue(signUpButton.waitForExistence(timeout: .regular))
        signUpButton.tap()
        
        try fillInInitialPage(email: email)
        
        let passwordEnrollmentPage = FactorsEnrollmentPage(app: app)
        XCTAssertTrue(passwordEnrollmentPage.passwordLabel.waitForExistence(timeout: .regular))
        passwordEnrollmentPage.passwordLabel.tap()
        
        passwordEnrollmentPage.continueButton.tap()
        
        let passwordPage = PasscodeFormPage(app: app, isSecure: true)
        XCTAssertTrue(passwordPage.passcodeLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(passwordPage.securityPasscodeField.exists)
        
        if !passwordPage.securityPasscodeField.isFocused {
            passwordPage.securityPasscodeField.tap()
        }
        
        let credentials = try XCTUnwrap(scenario.credentials)
        passwordPage.securityPasscodeField.typeText(credentials.password)

        passwordPage.continueButton.tap()
        
        let factorEnrolmentPage = FactorsEnrollmentPage(app: app)
        XCTAssertTrue(factorEnrolmentPage.emailLabel.waitForExistence(timeout: .regular))
        factorEnrolmentPage.emailLabel.tap()
        factorEnrolmentPage.continueButton.tap()
        
        let codePage = PasscodeFormPage(app: app)
        XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(codePage.passcodeField.exists)
        
        if !codePage.passcodeField.isFocused {
            codePage.passcodeField.tap()
        }

        let emailCode = try receive(code: .email)

        codePage.passcodeField.typeText(emailCode)
        codePage.continueButton.tap()
        
        // Sometimes tests are very quick. And there's a strange bug after Continue button pressed.
        // UI is updated faster than the events delivered
        Thread.sleep(forTimeInterval: 2)
    }
    
    private func fillInInitialPage(email: String) throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let registrationPage = RegistrationFormPage(app: app)
        
        XCTAssertTrue(registrationPage.firstNameLabel.waitForExistence(timeout: .regular))
        XCTAssertTrue(registrationPage.firstNameField.exists)
        
        XCTAssertTrue(registrationPage.lastNameLabel.exists)
        XCTAssertTrue(registrationPage.lastNameField.exists)
        
        XCTAssertTrue(registrationPage.emailLabel.exists)
        XCTAssertTrue(registrationPage.emailField.exists)
        
        registrationPage.firstNameField.tap()
        registrationPage.firstNameField.typeText(credentials.firstName)
        registrationPage.lastNameField.tap()
        registrationPage.lastNameField.typeText(credentials.lastName)
        registrationPage.emailField.tap()
        registrationPage.emailField.typeText(email)
        
        signUpButton.tap()
    }
    
    private func fillInPhonePage(phone: String) {
        let factorsPage = FactorsEnrollmentPage(app: app)
        XCTAssertTrue(factorsPage.phoneLabel.waitForExistence(timeout: .regular))
        factorsPage.phoneLabel.tap()
        
        // Picker issue
        Thread.sleep(forTimeInterval: 2)
        
        XCTAssertTrue(factorsPage.phonePicker.waitForExistence(timeout: .regular))
        factorsPage.selectPickerWheel(.sms)
        
        let phoneFormPage = PhoneFormPage(app: app)

        XCTAssertTrue(phoneFormPage.phoneField.waitForExistence(timeout: .regular))
        
        if !phoneFormPage.phoneField.isFocused {
            phoneFormPage.phoneField.tap()
        }
        
        phoneFormPage.phoneField.typeText(phone)
        
        continueButton.tap()
    }
}
