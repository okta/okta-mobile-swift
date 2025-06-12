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

final class SocialAuthTests: ScenarioTestCase {
    
    static override var category: Scenario.Category { .socialAuth }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try XCTSkipIf(scenario.socialAuthCredentials == nil,
                      "Skipping social auth tests since no user credentials are defined")

    }
    
    func test_Sign_In() throws {
        let credentials = try XCTUnwrap(scenario.socialAuthCredentials)
        let policyDeactivatedExpectation = expectation(description: "Social MFA policy deactivated.")
        
        scenario.validator.deactivatePolicy(.socialAuthMFA) { _ in
            policyDeactivatedExpectation.fulfill()
        }
        
        wait(for: [policyDeactivatedExpectation], timeout: .regular)
        
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
        XCTAssertTrue(initialSignInButton.waitForExistence(timeout: .regular))
        initialSignInButton.tap()

        let signInPage = SignInFormPage(app: app)
        
        test("WHEN she clicks the 'Social Login' button") {
            
            test("AND logs in to an IdP") {
                XCTAssertTrue(signInPage.socialLoginButton.waitForExistence(timeout: .regular))
                signInPage.socialLoginButton.tap()
                
                let authorizationPage = AuthorizationWebPage(app: app)
                XCTAssertTrue(authorizationPage.webView.waitForExistence(timeout: .regular))
                XCTAssertTrue(authorizationPage.usernameTextField.firstMatch.waitForExistence(timeout: .regular))
                XCTAssertTrue(authorizationPage.passwordTextField.firstMatch.waitForExistence(timeout: .regular))
                
                authorizationPage.usernameTextField.tap()
                authorizationPage.usernameTextField.typeText(credentials.username)
                authorizationPage.passwordTextField.tap()
                authorizationPage.passwordTextField.typeText(credentials.password)
                
                authorizationPage.signInButton?.tap()
            }
        }
    }
}
