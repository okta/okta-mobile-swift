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

class MigrationTests: XCTestCase {
    lazy var username: String? = {
        ProcessInfo.processInfo.environment["E2E_USERNAME"]
    }()

    lazy var password: String? = {
        ProcessInfo.processInfo.environment["E2E_PASSWORD"]
    }()
    
    lazy var launchScreen: LaunchScreen = { LaunchScreen(self) }()
    lazy var profileScreen: ProfileScreen = { ProfileScreen(self) }()

    override func setUpWithError() throws {
        let app = XCUIApplication()
        app.launchEnvironment = ["AutoCorrection": "Disabled"]
        app.launchArguments = ["--reset-keychain"]
        app.launch()
        
        continueAfterFailure = false
    }

    func testValidMigration() throws {
        launchScreen.isVisible()
        XCTAssertEqual(launchScreen.state, .notSignedIn)

        launchScreen.setEphemeral(true)
        launchScreen.login(username: username, password: password)
        
        XCTAssertEqual(launchScreen.state, .migrationAvailable)
        save(screenshot: "Before migration")
        launchScreen.migrate()

        XCTAssertEqual(launchScreen.state, .migrationSuccessful)

        launchScreen.openProfile()

        profileScreen.wait()
        save(screenshot: "Profile Screen")

        XCTAssertEqual(profileScreen.valueLabel(for: .username).label, username)
        XCTAssertEqual(profileScreen.valueLabel(for: .defaultCredential).label, "Yes")
        
        profileScreen.signOut(.endSession)
        launchScreen.isVisible()
        
        XCTAssertEqual(launchScreen.state, .notSignedIn)
    }
}
