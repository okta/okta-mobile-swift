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

final class SocialAuthTests: ScenarioTestCase {
    
    static override var category: Scenario.Category { .socialAuth }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try XCTSkipIf(scenario.socialAuthCredentials == nil,
                      "Skipping social auth tests since no user credentials are defined")
    }
    
    func test_Sign_In() throws {
        let credentials = try XCTUnwrap(scenario.socialAuthCredentials)
        let policyDeactivatedExpaction = expectation(description: "Social MFA policy deactivated.")
        
        scenario.validator.deactivatePolicy(.socialAuthMFA) { _ in
            policyDeactivatedExpaction.fulfill()
        }
        
        wait(for: [policyDeactivatedExpaction], timeout: .regular)
        
        try signInSocialAuth(with: credentials)
                
        let userInfoPage = UserInfoPage(app: app)
        userInfoPage.assert(with: credentials)
    }
    
    func DISABLED_test_Sign_In_with_MFA() throws {
        let credentials = try XCTUnwrap(scenario.socialAuthCredentials)
        
        try signInSocialAuth(with: credentials)
        
        // Based on final decision implementation come here.
    }
    
    private func signInSocialAuth(with credentials: Scenario.Credentials) throws {
        let signInPage = SignInFormPage(app: app)
        
        test("WHEN she clicks the 'Login with Facebook' button") {
            XCTAssertTrue(signInPage.initialSignInButton.waitForExistence(timeout: .regular))
            signInPage.initialSignInButton.tap()
            
            test("AND logs in to Facebook") {
                XCTAssertTrue(signInPage.facebookSignInButton.waitForExistence(timeout: .regular))
                signInPage.facebookSignInButton.tap()
                
                if signInPage.socialAuthContinueButton.waitForExistence(timeout: .minimal) {
                    signInPage.socialAuthContinueButton.tap()
                }
                
                let authorizationPage = AuthorizationWebPage(app: app)
                XCTAssertTrue(authorizationPage.webView.waitForExistence(timeout: .regular))
                XCTAssertTrue(authorizationPage.usernameTextField.firstMatch.waitForExistence(timeout: .regular))
                XCTAssertTrue(authorizationPage.passwordTextField.firstMatch.waitForExistence(timeout: .regular))
                
                // When FB web page is open, it localizes the page according to your IP location.
                // So the language can be anything, that's why we are looking for english button to localize it.
                if authorizationPage.signInButton?.exists == true {
                    authorizationPage.englishLanguageButton?.tap()
                }
                
                // Wait for page localization
                Thread.sleep(forTimeInterval: 2)
                
                authorizationPage.usernameTextField.tap()
                authorizationPage.usernameTextField.typeText(credentials.username)
                authorizationPage.passwordTextField.tap()
                authorizationPage.passwordTextField.typeText(credentials.password)
                
                authorizationPage.signInButton?.tap()
            }
        }
    }
}
