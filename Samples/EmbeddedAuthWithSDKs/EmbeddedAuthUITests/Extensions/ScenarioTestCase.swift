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

import Foundation
import XCTest

class ScenarioTestCase: XCTestCase {
    private(set) var app: XCUIApplication!
    private(set) static var scenario: Scenario!
    var scenario: Scenario {
        type(of: self).scenario
    }
    
    class var category: Scenario.Category { .passcodeOnly }
    
    var shouldResetUser: Bool = true {
        didSet {
            app.launchArguments = launchArguments()
        }
    }
    
    func launchArguments() -> [String] {
        var result = [
            "--clientId", scenario.configuration.clientId,
            "--issuer", scenario.configuration.issuerUrl,
            "--scopes", scenario.configuration.scopes,
            "--redirectUri", scenario.configuration.redirectUri
        ]
        
        if shouldResetUser {
            result.append("--reset-user")
        }
        
        return result
    }

    override class func setUp() {
        do {
            scenario = try Scenario(category)
            try scenario.setUp()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    override class func tearDown() {
        do {
            try scenario.tearDown()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launchArguments = launchArguments()
        app.launch()
        
        continueAfterFailure = false

        XCTAssertEqual(app.staticTexts["clientIdLabel"].label, "Client ID: \(scenario.configuration.clientId)")
    }
}
