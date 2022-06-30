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

class ClassicAuthSignInTests: XCTestCase {
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["E2E_USERNAME"]
    }()

    lazy var password: String? = {
        ProcessInfo.processInfo.environment["E2E_PASSWORD"]
    }()
    
    lazy var clientId: String? = {
        ProcessInfo.processInfo.environment["E2E_CLIENT_ID"]
    }()

    lazy var signInScreen: ClassicSignInScreen = { ClassicSignInScreen(self) }()
    lazy var profileScreen: ProfileScreen = { ProfileScreen(self) }()

    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain"]
        app.launch()
        
        continueAfterFailure = false
    }
    
    func testSignIn() throws {
        signInScreen.isVisible()
        signInScreen.validate(clientId: try XCTUnwrap(clientId))
        save(screenshot: "Sign In Screen")

        signInScreen.login(username: try XCTUnwrap(username),
                           password: try XCTUnwrap(password))
        save(screenshot: "Logging In")
        
        profileScreen.wait()
        save(screenshot: "Profile Screen")

        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
        
        profileScreen.signOut(.revoke)
        
        signInScreen.isVisible()
    }
}
