//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class SingleSignOnTests: XCTestCase {
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["E2E_USERNAME"]
    }()

    lazy var password: String? = {
        ProcessInfo.processInfo.environment["E2E_PASSWORD"]
    }()
    
    lazy var ssoApp: XCUIApplication = {
        let app = XCUIApplication()
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain"]
        
        return app
    }()
    
    lazy var webSignInApp: XCUIApplication = {
        let codeDisambuguator = ProcessInfo.processInfo.environment["SAMPLE_CODE_DISAMBIGUATOR"] ?? ""
        
        let app = XCUIApplication(bundleIdentifier: "com.example.okta-sample.WebSignIn\(codeDisambuguator)")
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain", "--disable-keyboard"]

        return app
    }()
    
    lazy var signInScreen: SignInScreen = { SignInScreen(self, app: webSignInApp) }()
    lazy var webProfileScreen: ProfileScreen = { ProfileScreen(self, app: webSignInApp) }()
    lazy var ssoProfileScreen: ProfileScreen = { ProfileScreen(self, app: ssoApp) }()

    override func setUpWithError() throws {
        ssoApp.launch()
        ssoApp.terminate()
        ssoApp.launchArguments = []

        webSignInApp.launch()
        
        continueAfterFailure = false
    }
    
    func testSingleSignIn() throws {
        webSignInApp.activate()
        
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)

        webProfileScreen.wait()
        ssoApp.launch()
        
        ssoProfileScreen.wait()
        XCTAssertEqual(ssoProfileScreen.valueLabel(for: .username).label, username)
        XCTAssertEqual(ssoProfileScreen.valueLabel(for: .defaultCredential).label, "Yes")
        
        ssoProfileScreen.signOut(.revoke)
        webSignInApp.activate()
        webProfileScreen.signOut(.endSession)
    }
}
