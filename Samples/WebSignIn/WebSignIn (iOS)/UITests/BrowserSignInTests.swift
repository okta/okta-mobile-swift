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

class BrowserSignInUITests: XCTestCase {
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["E2E_USERNAME"]
    }()

    lazy var password: String? = {
        ProcessInfo.processInfo.environment["E2E_PASSWORD"]
    }()
    
    lazy var signInScreen: SignInScreen = { SignInScreen(self) }()
    lazy var profileScreen: ProfileScreen = { ProfileScreen(self) }()

    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain", "--disable-keyboard"]
        app.launch()
        
        continueAfterFailure = false
    }
    
    func testCancel() throws {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login()
        signInScreen.cancel()
        signInScreen.isVisible()
    }

    func testEphemeralLoginAndSignOut() throws {
        signInScreen.isVisible()
        signInScreen.setEphemeral(true)
        signInScreen.login(username: username, password: password)

        profileScreen.wait()
        save(screenshot: "Profile Screen")
                
        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
        
        profileScreen.signOut(.endSession)
        
        signInScreen.isVisible()
    }

    func testSharedLoginAndSignOut() throws {
        signInScreen.isVisible()
        signInScreen.setEphemeral(false)
        signInScreen.login(username: username, password: password)

        profileScreen.wait()
        save(screenshot: "Profile Screen")
        
        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
        
        profileScreen.signOut(.endSession)
        
        signInScreen.isVisible()
    }
}
