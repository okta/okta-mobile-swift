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

class DeviceCodeScreen: Screen {
    let app = XCUIApplication()
    let testCase: XCTestCase

    lazy var urlPromptLabel = app.staticTexts["url_prompt_label"]
    lazy var codeLabel = app.staticTexts["code_label"]
    lazy var openBrowserButton = app.buttons["open_browser_button"]

    init(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    func isVisible(timeout: TimeInterval = 3) {
        XCTAssertTrue(urlPromptLabel.waitForExistence(timeout: timeout))
    }
    
    var authorizeUrl: URL? {
        let text = urlPromptLabel.label
        guard let regex = try? NSRegularExpression(pattern: "Visit (\\S+)"),
              let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.count))
        else { return nil }
        
        guard let range = Range(match.range(at: 1), in: text) else { return nil }
        
        return URL(string: "https://" + String(text[range]))
    }
    
    var userCode: String? {
        codeLabel.label
    }
    
    func openBrowser() {
        XCTAssertTrue(openBrowserButton.exists)
        openBrowserButton.tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: .long))
    }
}
