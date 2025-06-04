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

import Foundation
import XCTest

protocol ReceivesCode {
    func receive(code type: A18NProfile.MessageType, timeout: TimeInterval, pollInterval: TimeInterval, scenario: Scenario, app: XCUIApplication) throws -> String
}

extension ReceivesCode {
    func receive(code type: A18NProfile.MessageType, timeout: TimeInterval = 30, pollInterval: TimeInterval = 1, scenario: Scenario, app: XCUIApplication) throws -> String {
        do {
            return try scenario.receive(code: type,
                                        timeout: timeout,
                                        pollInterval: pollInterval)
        } catch {
            let sendAgain = app.tables.staticTexts["Send again"]
            guard sendAgain.exists else {
                throw error
            }
            
            sendAgain.tap()
            return try scenario.receive(code: type,
                                        timeout: timeout,
                                        pollInterval: pollInterval)
        }
    }
}

class ScenarioTestCase: XCTestCase, ReceivesCode {
    private(set) var app: XCUIApplication!
    private static var scenario: Scenario?
    var scenario: Scenario!
    
    class var category: Scenario.Category { .passcodeOnly }
    
    var shouldResetUser: Bool = true {
        didSet {
            app.launchArguments = launchArguments()
        }
    }
    
    var initialSignInButton: XCUIElement { app.buttons["Sign In"] }
    
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
    
    func receive(code type: A18NProfile.MessageType, timeout: TimeInterval = 30, pollInterval: TimeInterval = 1) throws -> String {
        try receive(code: type, timeout: timeout, pollInterval: pollInterval, scenario: scenario, app: app)
    }

    override func setUpWithError() throws {
        if let scenario = type(of: self).scenario {
            self.scenario = scenario
        } else {
            scenario = try Scenario(type(of: self).category)
            type(of: self).scenario = scenario
            try scenario.setUp()
        }
        
        app = XCUIApplication()
        if shouldResetUser {
            app.terminate()
        }
        
        switch app.state {
        case .runningBackground:
            app.activate()
            fallthrough
            
        case .runningForeground:
            let cancelButton = app.navigationBars.buttons["Cancel"]
            let signOutButton = app.tables.cells.staticTexts["Sign Out"]
            if cancelButton.exists {
                cancelButton.tap()
            }
            
            else if signOutButton.exists {
                signOutButton.tap()
                app.sheets.buttons["Revoke tokens"].tap()
            }
            
        default:
            app.launchArguments = launchArguments()
            app.launch()
        }
        
        continueAfterFailure = false
        
        test("GIVEN Mary navigates to the Basic Login View") {
            XCTAssertEqual(app.staticTexts["clientIdLabel"].label, "Client ID: \(scenario.configuration.clientId)")
        }
    }
    
    override class func tearDown() {
        do {
            try scenario?.tearDown()
            scenario = nil
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
