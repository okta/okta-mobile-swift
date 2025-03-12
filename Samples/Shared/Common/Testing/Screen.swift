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

protocol Screen {
    var app: XCUIApplication { get }
    var testCase: XCTestCase { get }

    var nextScreenButton: XCUIElement? { get }

    @discardableResult
    func dismissKeyboard() -> Bool

    @discardableResult
    func tapKeyboardNextOrGo() -> Bool
}

fileprivate enum WebViewNextButtonLabels: String, CaseIterable {
    case go = "Go"
    case next = "Next"
    case verify = "Verify"
}

extension Screen {
    var nextScreenButton: XCUIElement? {
        for buttonLabel in WebViewNextButtonLabels.allCases {
            let nextScreenButton = app.webViews.buttons[buttonLabel.rawValue]
            if nextScreenButton.exists {
                return nextScreenButton
            }
        }
        return nil
    }

    @discardableResult
    func tapKeyboardNextOrGo() -> Bool {
        #if !os(tvOS)
        if let submitButton = app.keyboardSubmitButton {
            submitButton.tap()
            return true
        } else if let nextButton = nextScreenButton {
            nextButton.tap()
            return true
        }
        #endif
        return false
    }
    
    @discardableResult
    func dismissKeyboard() -> Bool {
        #if os(tvOS)
        // TODO: Update this in the future to select the appropriately named button.
        XCUIRemote.shared.press(.select)
        #else
        let doneButton = app.toolbars.matching(identifier: "Toolbar").buttons["Done"]
        if app.keyboards.element(boundBy: 0).exists {
            if UIDevice.current.userInterfaceIdiom == .pad {
                app.keyboards.buttons["Hide keyboard"].tap()
                return true
            } else {
                app.toolbars.buttons["Done"].tap()
                return true
            }
        } else if doneButton.exists {
            doneButton.tap()
            return true
        }
        #endif
        return false
    }
}
