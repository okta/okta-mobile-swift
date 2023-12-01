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
    
    func dismissKeyboard()
    func tapKeyboardNextOrGo()
}

extension Screen {
    func tapKeyboardNextOrGo() {
        #if os(iOS)
        if app.keyboards.buttons["Next"].exists {
            app.keyboards.buttons["Next"].tap()
        } else if app.keyboards.buttons["Go"].exists {
            app.keyboards.buttons["Go"].tap()
        } else {
            dismissKeyboard()
        }
        #endif
    }
    
    func dismissKeyboard() {
        #if os(tvOS)
        // TODO: Update this in the future to select the appropriately named button.
        XCUIRemote.shared.press(.select)
        #else
        let doneButton = app.toolbars.matching(identifier: "Toolbar").buttons["Done"]
        if app.keyboards.element(boundBy: 0).exists {
            if UIDevice.current.userInterfaceIdiom == .pad {
                app.keyboards.buttons["Hide keyboard"].tap()
            } else {
                app.toolbars.buttons["Done"].tap()
            }
        } else if doneButton.exists {
            doneButton.tap()
        }
        #endif
    }
}
