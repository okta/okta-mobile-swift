//
//  MFAOktaSOPScenarioTests.swift
//  OktaIdxExampleUITests
//
//  Created by Mike Nachbaur on 2021-01-21.
//

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
