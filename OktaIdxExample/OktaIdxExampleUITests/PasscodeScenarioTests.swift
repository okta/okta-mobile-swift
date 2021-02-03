//
//  PasscodeScenarioTests.swift
//  PasscodeScenarioTests
//
//  Created by Mike Nachbaur on 2021-01-04.
//

import XCTest

class PasscodeScenarioTests: XCTestCase {
    let credentials = TestCredentials(with: .passcode)

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

    func testSuccessfulPasscode() throws {
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

        app.buttons["Sign in"].tap()
        
        // Password
        XCTAssertTrue(app.staticTexts["passcode.label"].waitForExistence(timeout: 5.0))
        XCTAssertEqual(app.staticTexts["passcode.label"].label, "Password")
        
        let passwordField = app.secureTextFields["passcode.field"]
        XCTAssertEqual(passwordField.value as? String, "")
        if !passwordField.isFocused {
            passwordField.tap()
        }
        passwordField.typeText(credentials.password)

        app.buttons["Continue"].tap()
        
        // Token
        XCTAssertTrue(app.navigationBars["Token"].waitForExistence(timeout: 5.0))
        XCTAssertFalse(app.staticTexts["No token was found"].exists)
    }

    func testUnsuccessfulPasscode() throws {
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

        app.buttons["Sign in"].tap()
        
        // Password
        XCTAssertTrue(app.staticTexts["passcode.label"].waitForExistence(timeout: 5.0))
        XCTAssertEqual(app.staticTexts["passcode.label"].label, "Password")
        
        let passwordField = app.secureTextFields["passcode.field"]
        XCTAssertEqual(passwordField.value as? String, "")
        if !passwordField.isFocused {
            passwordField.tap()
        }
        passwordField.typeText("InvalidPassword")

        app.buttons["Continue"].tap()

        let incorrectPasswordLabel = app.tables.staticTexts["Password is incorrect"]
        XCTAssertTrue(incorrectPasswordLabel.waitForExistence(timeout: 5.0))
        XCTAssertTrue(incorrectPasswordLabel.exists)
    }

}
