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

import Foundation
import XCTest
import SwiftOTP

class SignInScreen: Screen {
    let app = XCUIApplication()
    let testCase: XCTestCase
    
    enum State {
        case primaryFactor
        case secondaryFactor
    }
    
    enum Factor: String {
        case password = "Password"
        case otp = "One-Time Code"
        case push = "Push Notification"
        
        var accessibilityIdentifier: String {
            rawValue
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
                .appending("_button")
        }
        
        func value(from input: String?) -> String? {
            switch self {
            case .push:
                return nil
            case .password:
                return input
            case .otp:
                guard let secretString = input,
                      let secret = base32DecodeToData(secretString),
                      let totp = TOTP(secret: secret)
                else {
                    return nil
                }

                return totp.generate(time: .now)
            }
        }
    }
    
    lazy var signInButton = app.buttons["signin_button"]
    lazy var clientIdLabel = app.buttons["client_id_label"]
    
    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    func isVisible(timeout: TimeInterval = 3) {
        XCTAssertTrue(app.staticTexts["Direct Authentication Sign In"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.staticTexts["Not configured"].exists)
    }
    
    func validate(clientId: String) {
        XCTAssertEqual(clientIdLabel.label, clientId)
    }
    
    func validate(state: State) {
        switch state {
        case .primaryFactor:
            XCTAssertTrue(app.textFields["username_field"].waitForExistence(timeout: .standard))
        case .secondaryFactor:
            XCTAssertTrue(app.staticTexts["Please authenticate using an additional factor."].waitForExistence(timeout: .standard))
        }
    }
    
    func login(username: String? = nil, factor: Factor, value: String? = nil) {
        if factorTypeButton.label != factor.rawValue {
            factorTypeButton.tap()
            app.buttons[factor.rawValue].tap()
        }

        if let username = username,
           app.textFields.firstMatch.waitForExistence(timeout: .standard)
        {
            let field = app.textFields["username_field"]
            field.tap()
            
            if let fieldValue = field.value as? String,
               !fieldValue.isEmpty
            {
                usleep(useconds_t(1000)) // Wait for the field to be selected
                field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            }
            
            field.typeText(username)
        }
        
        if let value = factor.value(from: value) {
            var field = app.textFields[factor.accessibilityIdentifier]
            if !field.exists {
                field = app.secureTextFields[factor.accessibilityIdentifier]
            }
            
            if field.exists {
                field.tap()
                
                field.typeText(value)
            }
        }
        
        signInButton.tap()
    }
    
    private var factorTypeButton: XCUIElement {
        app.buttons["factor_type_button"]
    }
}
