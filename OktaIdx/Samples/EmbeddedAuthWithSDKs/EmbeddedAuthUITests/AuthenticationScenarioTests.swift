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

final class AuthenticationScenarioTests: ScenarioTestCase {
    class override var category: Scenario.Category { .passcodeOnly }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try scenario.createUser()

        shouldResetUser = true
    }
    
    func test_Authentication_Session() throws {
        XCTAssertTrue(initialSignInButton.waitForExistence(timeout: .regular))
        initialSignInButton.tap()
        
        let credentials = try XCTUnwrap(scenario.credentials)
        let signInPage = SignInFormPage(app: app)
        signInPage.signIn(username: credentials.username, password: credentials.password)
        
        // Token
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
        
        test("AND Mary sees a logout button") {
            XCTAssertTrue(app.staticTexts["Sign Out"].exists)
        }
    }
    
    func test_Sign_Out() throws {
        try test("GIVEN Mary has an authenticated session") {
            try test_Authentication_Session()
            shouldResetUser = false
            
            test("AND Mary navigates to the Root View") {
                app.terminate()
                app.launch()
            }
        }
        
        test("WHEN Mary clicks the logout button") {
            XCTAssertTrue(app.staticTexts["Sign Out"].waitForExistence(timeout: .regular))
            app.staticTexts["Sign Out"].tap()
            app.buttons["Clear tokens"].tap()
        }
        
        test("THEN she is redirected back to the Root View") {
            XCTAssertTrue(app.buttons["Sign In"].waitForExistence(timeout: .regular))
            
            test("AND Mary sees login, registration buttons") {
                XCTAssertTrue(app.staticTexts["clientIdLabel"].exists)
                XCTAssertEqual(app.staticTexts["clientIdLabel"].label, "Client ID: \(scenario.configuration.clientId)")
            }
        }
    }
}
