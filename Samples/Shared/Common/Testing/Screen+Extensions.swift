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

protocol WebLogin {
    var signInButton: XCUIElement { get }
    var ephemeralSwitch: XCUIElement { get }
    var isEphemeral: Bool { get }
    
    func setEphemeral(_ enabled: Bool)
    func login(username: String?, password: String?)
    func cancel()
}

extension WebLogin {
    var isEphemeral: Bool {
        ephemeralSwitch.isOn ?? false
    }
}

extension WebLogin where Self: Screen {
    func setEphemeral(_ enabled: Bool) {
        if ephemeralSwitch.isOn != enabled {
            ephemeralSwitch.tap()
        }
    }
    
    func login(username: String? = nil, password: String? = nil) {
        if !app.webViews.firstMatch.exists {
            if signInButton.exists {
                signInButton.tap()
            }
            
            if !isEphemeral {
                testCase.tapAlertButton(named: "Continue")
            }
        }

        guard app.webViews.firstMatch.waitForExistence(timeout: .long) else { return }
        send(username: username)
        send(password: password)

        _ = app.webViews.firstMatch.waitForNonExistence(timeout: .standard)
    }
    
    func send(username: String? = nil) {
        guard let username else { return }

        let pageTransitionElement = app
            .webViews
            .staticTexts
            .matching(NSPredicate(format: "label IN %@", ["Keep me signed in", "Username", "Sign In"]))
            .waitForExistence(timeout: .veryLong)

        if app.webViews.textFields.firstMatch.waitForExistence(timeout: .standard) {
            let field = app.webViews.textFields.element(boundBy: 0)
            let fieldValue = field.value as? String ?? ""
            if fieldValue != username {
                field.tap()
                _ = app.keyboards.firstMatch.waitForExistence(timeout: .standard)
                
                if !fieldValue.isEmpty {
                    usleep(useconds_t(1000)) // Wait for the field to be selected
                    field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
                    field.typeText("")
                    usleep(useconds_t(500))
                }
                
                field.typeText(username)
            }

            tapKeyboardNextOrGo()

            if let pageTransitionElement,
               !pageTransitionElement.waitForNonExistence(timeout: .standard)
            {
                print("Error: Failed to transition to next page after entering username")
            }
        }
    }

    func select(authenticator: String) {
        let frame = app.webViews.staticTexts[authenticator].frame
        for link in app.webViews.links {
            guard link.label == "Select" ||
                    link.label == "Select \(authenticator)."
            else {
                continue
            }
            
            if link.frame.midY > frame.minY,
               link.frame.midY < frame.maxY
            {
                link.tap()
                return
            }
        }
    }
    
    func wait(for staticText: String, timeout: TimeInterval = .standard) -> Bool {
        guard app.staticTexts[staticText].waitForExistence(timeout: timeout) else { return false }
        if !app.staticTexts[staticText].isHittable {
            return app.staticTexts[staticText].waitToBeHittable(timeout: timeout)
        }
        return true
    }
    
    func send(password: String? = nil) {
        guard let password else { return }

        if app.webViews
            .staticTexts
            .matching(NSPredicate(format: "label IN %@", ["Verify it's you with a security method",
                                                          "Select from the following options",
                                                          "Select Password."]))
            .waitForExistence(timeout: .short) != nil
        {
            select(authenticator: "Password")
        }
        
        let pageTransitionElement = app
            .webViews
            .staticTexts
            .matching(NSPredicate(format: "label IN %@", ["Verify with your password", "Forgot password?"]))
            .waitForExistence(timeout: .long)

        if app.webViews.secureTextFields.firstMatch.waitForExistence(timeout: 5) {
            let field = app.webViews.secureTextFields.element(boundBy: 0)
            field.tap()
            _ = app.keyboards.firstMatch.waitForExistence(timeout: .standard)
            
            // Dismiss the password save reminder keyboard view in iOS 18+
            if app.otherElements["SFAutoFillInputView"].buttons["Not Now"].exists {
                app.otherElements["SFAutoFillInputView"].buttons["Not Now"].tap()
                usleep(useconds_t(500)) // Wait for the keyboard animation, since XCTest won't
                field.tap()
                _ = app.keyboards.firstMatch.waitForExistence(timeout: .standard)
            }

            field.typeText(password)

            tapKeyboardNextOrGo()

            if let pageTransitionElement,
               !pageTransitionElement.waitForNonExistence(timeout: .standard)
            {
                print("Error: Failed to transition to next page after entering password")
            }
        }
    }
    
    func cancel() {
        app.buttons["Cancel"].tap()
        
        XCTAssertTrue(app.alerts
            .staticTexts["Authentication cancelled by the user."]
            .waitForExistence(timeout: .short))
        
        app.alerts.buttons["OK"].tap()
    }
    
    private var keyboardDoneQuery: XCUIElement {
        app.toolbars.matching(identifier: "Toolbar").buttons["Done"]
    }
    
    private var signInButton: XCUIElement {
        app.webViews.buttons["Sign in"]
    }
    
    private var nextButton: XCUIElement {
        app.webViews.buttons["Next"]
    }
    
    private var verifyButton: XCUIElement {
        app.webViews.buttons["Verify"]
    }
}
