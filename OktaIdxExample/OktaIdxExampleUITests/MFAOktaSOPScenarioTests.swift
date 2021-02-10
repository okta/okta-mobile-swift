/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest

class MFAOktaSOPScenarioTests: XCTestCase {
    let credentials = TestCredentials(with: .mfasop)

    override func setUpWithError() throws {
        try XCTSkipIf(credentials == nil)
        
        let app = XCUIApplication()
        app.launchArguments = [
            "--clientId", credentials!.clientId,
            "--issuer", credentials!.issuerUrl,
            "--redirectUri", credentials!.redirectUri
        ]
        app.launch()

        continueAfterFailure = false
        
        XCTAssertEqual(app.textFields["issuerField"].value as? String, credentials!.issuerUrl)
        XCTAssertEqual(app.textFields["clientIdField"].value as? String, credentials!.clientId)
        XCTAssertEqual(app.textFields["redirectField"].value as? String, credentials!.redirectUri)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}
