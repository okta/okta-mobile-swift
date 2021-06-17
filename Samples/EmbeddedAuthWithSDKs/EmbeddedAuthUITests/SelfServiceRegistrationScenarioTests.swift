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
    
    func test_Sign_Up_With_Password_And_Email() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        
        signInButton.tap()
        
        try passEmailFactor(email: credentials.username)
        
        test("WHEN she selects 'Skip' on SMS") {
            XCTAssertTrue(skipButton.waitForExistence(timeout: .regular))
            skipButton.tap()
        }
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func test_Sign_Up_With_Password_And_Email_And_Phone() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let phoneNumber = try XCTUnwrap(scenario.profile?.phoneNumber)
        
        signInButton.tap()
        
        try passEmailAndPhoneFactors(email: credentials.username, phone: phoneNumber)
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func test_Sign_Up_With_Invalid_Email() throws {
        signInButton.tap()
        XCTAssertTrue(signUpButton.waitForExistence(timeout: .regular))
        signUpButton.tap()
        
        try fillInInitialPage(email: "invalid@email")
        
        test("THEN she sees the error messages") {
            XCTAssertTrue(app.tables.staticTexts["'Email' must be in the form of an email address"].waitForExistence(timeout: .regular))
            XCTAssertTrue(app.tables.staticTexts["Provided value for property 'Email' does not match required pattern"].waitForExistence(timeout: .minimal))
        }
    }
    
    func test_Sign_Up_With_Invalid_Phone() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        signInButton.tap()
        
        try passEmailFactor(email: credentials.username)
        
        fillInPhonePage(phone: "1230871234567")
        
        test("THEN she should see an error message") {
            XCTAssertTrue(app.tables.staticTexts["Unable to initiate factor enrollment: Invalid Phone Number."].waitForExistence(timeout: .regular))
        }
    }
    
    private func passEmailAndPhoneFactors(email: String, phone: String) throws {
        try passEmailFactor(email: email)
        
        fillInPhonePage(phone: phone)
        
        try test("THEN the screen changes to receive an input for a code") {
            let phonePasscodePage = PasscodeFormPage(app: app)
            XCTAssertTrue(phonePasscodePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(phonePasscodePage.passcodeField.exists)
            XCTAssertTrue(phonePasscodePage.continueButton.exists)
            
            try test("WHEN She inputs the correct code from her SMS") {
                let smsCode = try receive(code: .sms)

                if !phonePasscodePage.passcodeField.isFocused {
                    phonePasscodePage.passcodeField.tap()
                }
                
                phonePasscodePage.passcodeField.typeText(smsCode)
            }
            
            test("AND She selects 'Verify'") {
                phonePasscodePage.continueButton.tap()
            }
        }
    }
    
    private func passEmailFactor(email: String) throws {
        XCTAssertTrue(signUpButton.waitForExistence(timeout: .regular))
        signUpButton.tap()
        
        try fillInInitialPage(email: email)
        
        test("THEN she sees the Select Authenticator page with password as the only option") {
            let passwordEnrollmentPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(passwordEnrollmentPage.passwordLabel.waitForExistence(timeout: .regular))
            
            test("WHEN she chooses password factor option") {
                passwordEnrollmentPage.passwordLabel.tap()
            }
            
            test("AND she submits the select authenticator form") {
                passwordEnrollmentPage.continueButton.tap()
            }
        }
        
        try test("THEN she sees the set new password form") {
            let passwordPage = PasscodeFormPage(app: app, isSecure: true)
            XCTAssertTrue(passwordPage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(passwordPage.securityPasscodeField.exists)
            
            try test("WHEN she fills out her Password") {
                if !passwordPage.securityPasscodeField.isFocused {
                    passwordPage.securityPasscodeField.tap()
                }
                
                try test("AND she confirms her Password") {
                    let credentials = try XCTUnwrap(scenario.credentials)
                    passwordPage.securityPasscodeField.typeText(credentials.password)
                }
            }
            
            test("AND she submits the set new password form") {
                passwordPage.continueButton.tap()
            }
        }
        
        test("THEN she sees a list of required factors to setup") {
            let factorEnrolmentPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(factorEnrolmentPage.emailLabel.waitForExistence(timeout: .regular))
            test("WHEN she selects Email") {
                factorEnrolmentPage.emailLabel.tap()
            }
            
            test("THEN she submits a choice") {
                factorEnrolmentPage.continueButton.tap()
            }
        }
        
        try test("THEN she sees a page to input a code") {
            let codePage = PasscodeFormPage(app: app)
            XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(codePage.passcodeField.exists)
            
            try test("WHEN she inputs the correct code from her email") {
                if !codePage.passcodeField.isFocused {
                    codePage.passcodeField.tap()
                }
                
                let emailCode = try receive(code: .email)
                
                codePage.passcodeField.typeText(emailCode)
                codePage.continueButton.tap()
            }
        }
        
        // Sometimes tests are very quick. And there's a strange bug after Continue button pressed.
        // UI is updated faster than the events delivered
        Thread.sleep(forTimeInterval: 2)
    }
    
    private func fillInInitialPage(email: String) throws {
        try test("GIVEN Mary navigates to the Self Service Registration View") {
            let credentials = try XCTUnwrap(scenario.credentials)
            let registrationPage = RegistrationFormPage(app: app)
            
            XCTAssertTrue(registrationPage.firstNameLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(registrationPage.firstNameField.exists)
            
            XCTAssertTrue(registrationPage.lastNameLabel.exists)
            XCTAssertTrue(registrationPage.lastNameField.exists)
            
            XCTAssertTrue(registrationPage.emailLabel.exists)
            XCTAssertTrue(registrationPage.emailField.exists)
            
            test("WHEN she fills out her First Name") {
                registrationPage.firstNameField.tap()
                registrationPage.firstNameField.typeText(credentials.firstName)
            }
            
            test("AND she fills out her Last Name") {
                registrationPage.lastNameField.tap()
                registrationPage.lastNameField.typeText(credentials.lastName)
            }
            
            test("AND she fills out her Email") {
                registrationPage.emailField.tap()
                registrationPage.emailField.typeText(email)
            }
            
            test("AND she submits the registration form") {
                signUpButton.tap()
            }
        }
    }
    
    private func fillInPhonePage(phone: String) {
        test("THEN she sees a list of factors to register") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(factorsPage.phoneLabel.waitForExistence(timeout: .regular))
            
            test("WHEN she selects Phone from the list") {
                factorsPage.phoneLabel.tap()
                
                // Picker issue
                Thread.sleep(forTimeInterval: 2)
                
                test("AND She selects 'Receive a Code'") {
                    XCTAssertTrue(factorsPage.phonePicker.waitForExistence(timeout: .regular))
                    factorsPage.selectPickerWheel(.sms)
                }
                
                let phoneFormPage = PhoneFormPage(app: app)
                
                XCTAssertTrue(phoneFormPage.phoneField.waitForExistence(timeout: .regular))
                
                test("AND She inputs a phone number") {
                    if !phoneFormPage.phoneField.isFocused {
                        phoneFormPage.phoneField.tap()
                    }
                    
                    phoneFormPage.phoneField.typeText(phone)
                }
            }
            
            test("AND She selects 'Receive a Code'") {
                continueButton.tap()
            }
        }
    }
}
