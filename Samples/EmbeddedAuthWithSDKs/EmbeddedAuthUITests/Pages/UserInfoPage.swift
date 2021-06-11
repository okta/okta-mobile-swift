//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct UserInfoPage {
    enum Label {
        case firstname
        case lastname
        case username
    }
    
    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func label(_ type: Label, value: String) -> XCUIElement {
        switch type {
        case .firstname:
            return app.cells["givenName"].staticTexts.element(matching: .init(format: "label CONTAINS[c] %@", value))
        case .lastname:
            return app.cells["familyName"].staticTexts.element(matching: .init(format: "label CONTAINS[c] %@", value))
        case .username:
            return app.cells["username"].staticTexts.element(matching: .init(format: "label CONTAINS[c] %@", value))
        }
    }
    
    func assert(with credentials: Scenario.Credentials) {
        test("THEN she is redirected to the Root View") {
            test("AND the cell for the value of 'email' is shown and contains her email") {
                XCTAssertTrue(label(.username, value: credentials.username).waitForExistence(timeout: .regular))
            }
            
            test("AND the cell for the value of 'firstname' is shown and contains her first name") {
                XCTAssertTrue(label(.firstname, value: credentials.firstName).waitForExistence(timeout: .regular))
            }
            
            test("AND the cell for the value of 'lastname' is shown and contains her last name") {
                XCTAssertTrue(label(.lastname, value: credentials.lastName).waitForExistence(timeout: .regular))
            }
        }
    }
}
