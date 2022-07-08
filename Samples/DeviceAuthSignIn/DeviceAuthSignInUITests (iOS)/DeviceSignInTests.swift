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

class DeviceSignInTests: XCTestCase {
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["E2E_USERNAME"]
    }()

    lazy var password: String? = {
        ProcessInfo.processInfo.environment["E2E_PASSWORD"]
    }()

    lazy var domain: String? = {
        ProcessInfo.processInfo.environment["E2E_DOMAIN"]
    }()

    lazy var clientId: String? = {
        ProcessInfo.processInfo.environment["E2E_CLIENT_ID"]
    }()

    lazy var deviceCodeScreen: DeviceCodeScreen = { DeviceCodeScreen(self) }()
    lazy var browserSignInScreen: BrowserSignInScreen = { BrowserSignInScreen(self) }()
    lazy var profileScreen: ProfileScreen = { ProfileScreen(self) }()

    override func setUpWithError() throws {
        let domain = try XCTUnwrap(domain)
        let clientId = try XCTUnwrap(clientId)
        
        let app = XCUIApplication()
        app.launchArguments = [
            "--reset-keychain",
            "--enable-browser"
        ]
        app.launchEnvironment = [
            "E2E_DOMAIN": domain,
            "E2E_CLIENT_ID": clientId
        ]
        app.launch()
        
        continueAfterFailure = false
    }
    
    func testSignIn() throws {
        let username = try XCTUnwrap(username)
        let password = try XCTUnwrap(password)
        
        deviceCodeScreen.isVisible()
        save(screenshot: "Authorization Screen")

        let url = try XCTUnwrap(deviceCodeScreen.authorizeUrl)
        let code = try XCTUnwrap(deviceCodeScreen.userCode)
        
        XCTAssertNotNil(code)
        XCTAssertEqual(url.host, domain)
        
        deviceCodeScreen.openBrowser()
        browserSignInScreen.isVisible()

        save(screenshot: "Verify Code Screen")
        browserSignInScreen.verifyActivationCode(code)

        save(screenshot: "Login Screen")
        browserSignInScreen.login(username: username, password: password)

        profileScreen.wait()
        save(screenshot: "Profile Screen")
        
        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
        
        profileScreen.signOut(.revoke)
        
        deviceCodeScreen.isVisible()
    }
}
