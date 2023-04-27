//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct TestUser {
    let username: String
    let password: String
    let otpSecret: String
}

final class DirectAuth1FASignInTests: XCTestCase {
    lazy var user: TestUser? = {
        let env = ProcessInfo.processInfo.environment
        guard let username = env["E2E_USERNAME"],
              let password = env["E2E_PASSWORD"],
              let otpSecret = env["E2E_OTP_SECRET"]
        else {
            return nil
        }
        
        return .init(username: username, password: password, otpSecret: otpSecret)
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

    func testPassword() throws {
        let user = try XCTUnwrap(user)
        
        signInScreen.isVisible()
        signInScreen.validate(state: .primaryFactor)

        signInScreen.login(username: user.username, factor: .password, value: user.password)

        profileScreen.wait()
        save(screenshot: "Profile Screen")

        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, user.username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
    }

    func testOTP() throws {
        let user = try XCTUnwrap(user)
        
        signInScreen.isVisible()
        signInScreen.validate(state: .primaryFactor)
        signInScreen.login(username: user.username, factor: .otp, value: user.otpSecret)

        profileScreen.wait()
        save(screenshot: "Profile Screen")

        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, user.username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
    }
}
