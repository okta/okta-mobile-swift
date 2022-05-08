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

class ProfileScreen: Screen {
    let app = XCUIApplication()
    let testCase: XCTestCase

    private lazy var refreshButton = app.buttons["Refresh"]
    private lazy var signOutButton = app.tables.staticTexts["Sign Out"]
    private lazy var removeButton = app.sheets.buttons["Remove"]
    private lazy var revokeButton = app.sheets.buttons["Revoke tokens"]
    private lazy var endSessionButton = app.sheets.buttons["End a session"]

    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    func wait(timeout: TimeInterval = 3) {
        _ = app.tabBars.staticTexts["Profile"].waitForExistence(timeout: timeout)
        _ = app.navigationBars.staticTexts["Profile"].waitForNonExistence(timeout: timeout)
    }
    
    enum SignOutOption {
        case remove
        case revoke
        case endSession
    }
    
    enum Field: String {
        case givenName = "Given name"
        case familyName = "Family name"
        case locale = "Locale"
        case timeZone = "Timezone"
        case username = "Username"
        case userId = "User ID"
        case createdAt = "Created at"
        case defaultCredential = "Is Default"
        case tokenDetails = "Token details"
    }
    
    func valueLabel(for field: Field) -> XCUIElement {
        let fieldQuery = app.cells
            .containing(.staticText, identifier: field.rawValue)

        fieldQuery.firstMatch.waitForExistence(timeout: .standard)
        return fieldQuery.staticTexts
            .allElementsBoundByIndex[1]
    }
    
    func signOut(_ option: SignOutOption) {
        guard signOutButton.waitForExistence(timeout: .short) else {
            XCTFail("Cannot find the sign out table cell")
            return
        }
        
        signOutButton.tap()
        
        switch option {
        case .remove:
            removeButton.tap()
        case .revoke:
            revokeButton.tap()
        case .endSession:
            let alertObserver = testCase.addUIInterruptionMonitor(withDescription: "System Dialog") { (alert) -> Bool in
                alert.buttons["Continue"].tap()
                return true
            }
            
            defer {
                testCase.removeUIInterruptionMonitor(alertObserver)
            }

            endSessionButton.tap()
            app.tap()
            XCTAssertTrue(app.webViews.element.waitForNonExistence(timeout: .standard))
        }
    }
}
