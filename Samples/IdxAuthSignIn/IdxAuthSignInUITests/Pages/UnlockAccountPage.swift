//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct UnlockAccountPage {
    enum PickerWheel {
        case sms
        case voice
    }

    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    var usernameLabel: XCUIElement { app.staticTexts["identifier.label"] }
    var usernameField: XCUIElement { app.textFields["identifier.field"] }
    
    var emailButton: XCUIElement {
        app.staticTexts.allElementsBoundByIndex.first {
            $0.identifier == "authenticator.label" && $0.label == "Email"
        } ?? app.staticTexts["Email"]
    }
    
    var phoneButton: XCUIElement {
        app.staticTexts.allElementsBoundByIndex.first {
            $0.identifier == "authenticator.label" && $0.label == "Phone"
        } ?? app.staticTexts["Phone"]
    }
    
    var phonePicker: XCUIElement { app.pickers.firstMatch }

    var unlockButton: XCUIElement { app.buttons["button.Unlock Account"] }
    var nextButton: XCUIElement { app.buttons["button.Next"] }
    
    func button(for factor: A18NProfile.MessageType) -> XCUIElement? {
        switch factor {
        case .email:
            return emailButton
        case .sms:
            return phoneButton
        case .voice:
            return nil
        }
    }
    
    func selectPickerWheel(for factor: A18NProfile.MessageType) {
        switch factor {
        case .sms:
            app.pickers.firstMatch.pickerWheels.firstMatch.adjust(toPickerWheelValue: "SMS")
        case .voice:
            app.pickers.firstMatch.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Voice")
        case .email: break
        }
    }

    func unlock(username: String, factor: A18NProfile.MessageType) {
        test("GIVEN Mary choses account unlock") {
            XCTAssertTrue(usernameLabel.waitForExistence(timeout: .regular))
            XCTAssertTrue(usernameField.exists)
            
            test("AND she fills in her correct username") {
                usernameField.tap()
                usernameField.typeText(username)
            }
            
            test("AND selects the \(factor.rawValue) method") {
                button(for: factor)?.tap()
                
                // NOTE: There's currently a bug that prevents the select-authenticator form
                //       from working when filling out the phone number at that time.
                //       OKTA-453278
                unlockButton.tap()
                
                // Picker issue
                Thread.sleep(forTimeInterval: 2)

                selectPickerWheel(for: factor)
            }
            
            test("AND she submits the unlock form") {
                nextButton.tap()
            }
        }
    }
    
    func assert() {
        test("THEN she is redirected to the unlock account screen") {
            XCTAssertTrue(self.app.staticTexts["Unlock Account"].waitForExistence(timeout: .regular))
        }
    }
}
