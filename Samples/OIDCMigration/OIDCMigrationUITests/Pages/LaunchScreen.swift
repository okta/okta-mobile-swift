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

import Foundation
import XCTest

class LaunchScreen: Screen, WebLogin {
    let app = XCUIApplication()
    let testCase: XCTestCase
    
    lazy var ephemeralSwitch = app.switches["ephemeral_switch"]
    lazy var signInButton = app.buttons["sign_in_button"]
    private lazy var signOutButton = app.buttons["sign_out_button"]
    private lazy var migrateButton = app.buttons["migrate_button"]
    private lazy var openUserProfileButton = app.buttons["open_user_button"]
    private lazy var clientIdLabel = app.buttons["client_id_label"]

    enum State {
        case notSignedIn
        case migrationAvailable
        case migrationSuccessful
    }
    
    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    func isVisible(timeout: TimeInterval = 3) {
        XCTAssertTrue(app.staticTexts["Legacy OIDC Migration"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.staticTexts["Not configured"].exists)
    }
    
    func validate(clientId: String) {
        XCTAssertEqual(clientIdLabel.label, clientId)
    }
    
    func migrate() {
        migrateButton.tap()
        _ = openUserProfileButton.waitForExistence(timeout: .short)
    }
    
    func openProfile() {
        openUserProfileButton.tap()
    }
    
    var state: State? {
        if openUserProfileButton.exists && signInButton.exists && !signOutButton.exists {
            return .migrationSuccessful
        } else if signInButton.exists && !openUserProfileButton.exists {
            return .notSignedIn
        } else if migrateButton.exists && signOutButton.exists {
            return .migrationAvailable
        } else {
            return nil
        }
    }
}
