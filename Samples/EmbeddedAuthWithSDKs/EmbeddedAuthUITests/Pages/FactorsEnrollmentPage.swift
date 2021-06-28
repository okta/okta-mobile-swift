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

struct FactorsEnrollmentPage {
    enum PickerWheel {
        case sms
        case voice
    }
    
    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    var emailLabel: XCUIElement { app.staticTexts["Email"] }
    var phoneLabel: XCUIElement { app.staticTexts["Phone"] }
    var passwordLabel: XCUIElement { app.staticTexts["Password"] }
    var continueButton: XCUIElement { app.buttons["button.Next"] }
    var chooseButton: XCUIElement { app.buttons["button.Choose Method"] }
    
    var phonePicker: XCUIElement { app.pickers.firstMatch }
    var phoneNumberLabel: XCUIElement { app.staticTexts["phoneNumber.label"] }
    var phoneNumberField: XCUIElement { app.textFields["phoneNumber.field"] }
    
    func selectPickerWheel(_ value: PickerWheel) {
        switch value {
        case .sms:
            phonePicker.pickerWheels.firstMatch.adjust(toPickerWheelValue: "SMS")
        case .voice:
            phonePicker.pickerWheels.firstMatch.adjust(toPickerWheelValue: "Voice")
        }
    }
}
