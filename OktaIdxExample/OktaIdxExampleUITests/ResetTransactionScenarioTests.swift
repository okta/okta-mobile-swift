//
//  ResetTransactionScenarioTests.swift
//  OktaIdxExampleUITests
//
//  Created by Mike Nachbaur on 2021-01-25.
//

import XCTest

class ResetTransactionScenarioTests: XCTestCase {
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

    func testCancelMFARemediation() throws {
        guard let credentials = credentials else { return }

        let app = XCUIApplication()
        app.buttons["Log in"].tap()

        // Username
        XCTAssertTrue(app.staticTexts["identifier.label"].waitForExistence(timeout: 5.0))
        XCTAssertEqual(app.staticTexts["identifier.label"].label, "Username")
        XCTAssertEqual(app.staticTexts["rememberMe.label"].label, "Remember this device")
        
        let usernameField = app.textFields["identifier.field"]
        XCTAssertEqual(usernameField.value as? String, "")
        if !usernameField.isFocused {
            usernameField.tap()
        }
        usernameField.typeText(credentials.username)

        app.buttons["Continue"].tap()
        
        // Select remediation type
        XCTAssertTrue(app.tables.staticTexts["authenticator.label"].waitForExistence(timeout: 5.0))
        app.tables.staticTexts["Password"].tap()
        app.buttons["Continue"].tap()

        // Password
        let passwordField = app.secureTextFields["passcode.field"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5.0))
        XCTAssertEqual(app.staticTexts["passcode.label"].label, "Password")
        
        XCTAssertEqual(passwordField.value as? String, "")
        if !passwordField.isFocused {
            passwordField.tap()
        }
        passwordField.typeText(credentials.password)

        app.buttons["Continue"].tap()
        
        // Cancel remediation
        XCTAssertTrue(app.tables.staticTexts["authenticator.label"].waitForExistence(timeout: 5.0))
        app.buttons["Restart"].tap()

        // Back to the Username screen
        XCTAssertTrue(app.staticTexts["identifier.label"].waitForExistence(timeout: 5.0))
        XCTAssertEqual(app.staticTexts["identifier.label"].label, "Username")
        XCTAssertEqual(app.staticTexts["rememberMe.label"].label, "Remember this device")
    }
}
