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

final class EmailMFALoginScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .selfServiceRegistration }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try scenario.createUser(groups: [.mfa])

        XCTAssertTrue(initialSignInButton.waitForExistence(timeout: .regular))
        initialSignInButton.tap()
    }
    
    func test_Login_With_MFA_Email() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        test("THEN she is presented with an option to select Email to verify") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(factorsPage.emailLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(factorsPage.chooseButton.exists)
            
            test("WHEN She selects Email from the list") {
                factorsPage.emailLabel.tap()
            }
            
            test("AND She selects 'Receive a Code'") {
                factorsPage.chooseButton.tap()
            }
        }
        
        try test("THEN the screen changes to receive an input for a code") {
            let codePage = PasscodeFormPage(app: app, scenario: scenario)
            XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(codePage.passcodeField.exists)
            
            let emailCode = try receive(code: .email)
            
            test("WHEN She inputs the correct code from the Email") {
                codePage.passcodeField.tap()
                codePage.passcodeField.typeText(emailCode)
            }
            
            test("AND She selects 'Verify'") {
                codePage.continueButton.tap()
            }
        }
        
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func test_Login_With_Invalid_Code() throws {
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        test("THEN She sees a list of factors") {
            let factorsPage = FactorsEnrollmentPage(app: app)
            XCTAssertTrue(factorsPage.emailLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(factorsPage.chooseButton.exists)
            
            test("WHEN She has selected Email from the list of factors") {
                
                factorsPage.emailLabel.tap()
                factorsPage.chooseButton.tap()
            }
        }
        
        test("THEN She inputs the incorrect code from the email") {
            let codePage = PasscodeFormPage(app: app, scenario: scenario)
            XCTAssertTrue(codePage.passcodeLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(codePage.passcodeField.exists)
            
            codePage.passcodeField.tap()
            codePage.passcodeField.typeText("12345")
            
            codePage.continueButton.tap()
        }
        
        test("THEN she sees shows an error message") {
            XCTAssertTrue(app.staticTexts["Invalid code. Try again."].waitForExistence(timeout: .regular))
        }
    }
}
