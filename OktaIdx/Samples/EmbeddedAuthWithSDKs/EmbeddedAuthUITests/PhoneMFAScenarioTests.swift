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
import OktaSdk

final class PhoneMFAEnrollScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try? scenario.resetMessages(.sms)
        try scenario.createUser(groups: [.mfa, .phoneEnrollment])

        XCTAssertTrue(initialSignInButton.waitForExistence(timeout: .regular))
        initialSignInButton.tap()        
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try scenario.deleteUser()
    }
    
    func test_Enroll_With_SMS() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        try test("THEN she is presented with a list of factors") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            
            XCTAssertTrue(factorsPage.phoneLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(factorsPage.continueButton.exists)
            
            test("WHEN She selects SMS from the list") {
                factorsPage.phoneLabel.tap()
            }
            
            XCTAssertTrue(factorsPage.phonePicker.waitForExistence(timeout: .minimal))
            factorsPage.selectPickerWheel(.sms)
            
            XCTAssertTrue(factorsPage.phoneNumberLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(factorsPage.phoneNumberField.exists)
            
            try test("AND She inputs a valid phone number") {
                factorsPage.phoneNumberField.tap()
                factorsPage.phoneNumberField.typeText(try XCTUnwrap(scenario.profile?.phoneNumber))
            }
            
            test("AND She selects 'Receive a Code'") {
                factorsPage.continueButton.tap()
            }
        }
        
        try test("THEN the screen changes to receive an input for a code") {
            let passcodePage = PasscodeFormPage(app: app, scenario: scenario)
            XCTAssertTrue(passcodePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(passcodePage.passcodeField.exists)
            XCTAssertTrue(passcodePage.resendButton.exists)
            
            let smsCode = try receive(code: .sms)
            
            test("WHEN She inputs the correct code from the SMS") {
                passcodePage.passcodeField.tap()
                passcodePage.passcodeField.typeText(smsCode)
            }
            
            test("AND She selects 'Verify'") {
                passcodePage.continueButton.tap()
            }
        }
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func test_Enroll_With_Invalid_Phone() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        test("THEN she is presented with an option to select SMS to enroll") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            
            XCTAssertTrue(factorsPage.phoneLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(factorsPage.continueButton.exists)
            
            factorsPage.phoneLabel.tap()
            factorsPage.continueButton.tap()
            
            test("WHEN She selects SMS from the list") {
                XCTAssertTrue(factorsPage.phonePicker.waitForExistence(timeout: .minimal))
                factorsPage.selectPickerWheel(.sms)
            }
            
            XCTAssertTrue(factorsPage.phoneNumberField.exists)
            
            factorsPage.phoneNumberField.tap()
            
            test("AND She inputs a invalid phone number") {
                factorsPage.phoneNumberField.typeText("+123456789")
            }
            
            test("AND She selects 'Receive a Code'") {
                factorsPage.continueButton.firstMatch.tap()
            }
        }
        
        test("THEN she should see a message") {
            XCTAssertTrue(app.staticTexts["Invalid Phone Number."].waitForExistence(timeout: .regular))
        }
    }
}

final class PhoneMFALoginScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try? scenario.resetMessages(.sms)
        try scenario.createUser(enroll: [.sms], groups: [.mfa, .phoneEnrollment])

        initialSignInButton.tap()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        try scenario.deleteUser()
    }
    
    func test_Login_With_MFA_SMS() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        try test("THEN she is presented with an option to select SMS to verify") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(factorsPage.phoneLabel.waitForExistence(timeout: .minimal))
            factorsPage.phoneLabel.tap()
            
            test("WHEN She selects SMS from the list") {
                XCTAssertTrue(factorsPage.phonePicker.waitForExistence(timeout: .minimal))
                factorsPage.selectPickerWheel(.sms)
            }
            
            
            // Picker issue
            Thread.sleep(forTimeInterval: 2)
            
            // Before receiving a code, we must reset all messages.
            try scenario.resetMessages(.sms)
            
            test("AND She selects 'Receive a Code'") {
                factorsPage.continueButton.tap()
            }
        }
        
        try test("THEN the screen changes to receive an input for a code") {
            let passcodePage = PasscodeFormPage(app: app, scenario: scenario)
            XCTAssertTrue(passcodePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(passcodePage.passcodeField.exists)
            XCTAssertTrue(passcodePage.resendButton.exists)
            
            let smsCode = try receive(code: .sms)
            
            test("WHEN She inputs the code from the SMS") {
                passcodePage.passcodeField.tap()
                passcodePage.passcodeField.typeText(smsCode)
            }
            
            test("AND She selects 'Verify'") {
                passcodePage.continueButton.tap()
            }
        }
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func test_Login_With_Invalid_Code() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        test("THEN she is presented with an option to select SMS to verify") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(factorsPage.phoneLabel.waitForExistence(timeout: .minimal))
            factorsPage.phoneLabel.tap()
            
            test("WHEN She selects SMS from the list") {
                XCTAssertTrue(factorsPage.phonePicker.waitForExistence(timeout: .minimal))
                factorsPage.selectPickerWheel(.sms)
            }
            
            // Picker issue
            Thread.sleep(forTimeInterval: 2)
            
            test("AND She selects 'Receive a Code'") {
                factorsPage.continueButton.tap()
            }
        }
        
        test("THEN the screen changes to receive an input for a code") {
            let passcodePage = PasscodeFormPage(app: app, scenario: scenario)
            XCTAssertTrue(passcodePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(passcodePage.passcodeField.exists)
            XCTAssertTrue(passcodePage.resendButton.exists)
            
            test("WHEN She inputs the incorrect code from the email") {
                passcodePage.passcodeField.tap()
                passcodePage.passcodeField.typeText("12345")
            }
            
            passcodePage.continueButton.tap()
        }
        
        test("THEN the sample show as error message") {
            XCTAssertTrue(app.staticTexts["Invalid code. Try again."].waitForExistence(timeout: .regular))
        }
    }
}
