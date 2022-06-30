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

class ClassicSignInScreen: Screen {
    let app = XCUIApplication()
    let testCase: XCTestCase
    
    lazy var usernameField = app.textFields["username_field"]
    lazy var passwordField = app.secureTextFields["password_field"]
    lazy var signInButton = app.buttons["sign_in_button"]
    lazy var clientIdLabel = app.staticTexts["client_id_label"]

    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    func isVisible(timeout: TimeInterval = 3) {
        XCTAssertTrue(app.staticTexts["Classic Native Auth"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.staticTexts["Not configured"].exists)
    }
    
    func validate(clientId: String) {
        XCTAssertEqual(clientIdLabel.label, clientId)
    }
    
    func login(username: String, password: String) {
        usernameField.tap()
        usernameField.typeText("\(username)\n")
        passwordField.typeText(password)
        signInButton.tap()
    }
}
