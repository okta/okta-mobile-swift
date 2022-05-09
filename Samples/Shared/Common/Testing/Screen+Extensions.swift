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

    func setEphemeral(_ enabled: Bool)
    func login(username: String?, password: String?)
    func cancel()
}

extension WebLogin where Self: Screen {
    func setEphemeral(_ enabled: Bool) {
        if ephemeralSwitch.isOn != enabled {
            ephemeralSwitch.tap()
        }
    }
    
    func login(username: String? = nil, password: String? = nil) {
        let alertObserver = testCase.addUIInterruptionMonitor(withDescription: "System Dialog") { (alert) -> Bool in
            alert.buttons["Continue"].tap()
            return true
        }
        
        defer {
            testCase.removeUIInterruptionMonitor(alertObserver)
        }

        signInButton.tap()

        let isEphemeral = ephemeralSwitch.isOn ?? false
        if !isEphemeral {
            app.tap()
        }

        guard app.webViews.firstMatch.waitForExistence(timeout: 5) else { return }
        
        if let username = username,
           app.webViews.textFields.firstMatch.waitForExistence(timeout: 5)
        {
            let field = app.webViews.textFields.element(boundBy: 0)
            if !field.hasFocus {
                field.tap()
            }
            
            if !isEphemeral,
               let fieldValue = field.value as? String,
               !fieldValue.isEmpty
            {
                field.clearText()
            }
            
            field.typeText(username)
        }
        
        if let password = password,
           app.webViews.secureTextFields.firstMatch.waitForExistence(timeout: 5)
        {
            let field = app.webViews.secureTextFields.element(boundBy: 0)
            if !field.hasFocus {
                field.tap()
            }
            
            field.typeText(password)
        }
        
        if username != nil || password != nil {
            app.webViews.buttons.firstMatch.tap()
        }
        
        _ = app.webViews.firstMatch.waitForNonExistence(timeout: .standard)
    }
    
    func cancel() {
        app.buttons["Cancel"].tap()
        
        XCTAssertTrue(app.alerts
            .staticTexts["Authentication cancelled by the user."]
            .waitForExistence(timeout: .short))
        
        app.alerts.buttons["OK"].tap()
    }
}
