//
//  OktaIdxExampleUITests.swift
//  OktaIdxExampleUITests
//
//  Created by Mike Nachbaur on 2021-01-04.
//

import XCTest

class OktaIdxExampleUITests: XCTestCase {
    let username = ProcessInfo.processInfo.environment["USERNAME"]
    let password = ProcessInfo.processInfo.environment["PASSWORD"]
    let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"]
    let issuer = ProcessInfo.processInfo.environment["ISSUER_DOMAIN"]
    let redirectUri = ProcessInfo.processInfo.environment["REDIRECT_URI"]

    override func setUpWithError() throws {
        try XCTSkipIf(clientId == nil || issuer == nil || redirectUri == nil)
        
        let app = XCUIApplication()
        app.launchArguments = [
            "--clientId", clientId!,
            "--issuer", "https://\(issuer!)",
            "--redirectUri", redirectUri!
        ]
        app.launch()

        continueAfterFailure = false
        
        XCTAssertEqual(app.textFields["issuerField"].value as? String, "https://\(issuer!)")
        XCTAssertEqual(app.textFields["clientIdField"].value as? String, clientId)
        XCTAssertEqual(app.textFields["redirectField"].value as? String, redirectUri)
    }

    func testSuccessfulPasscode() throws {
        try XCTSkipIf(username == nil || password == nil)

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
        usernameField.typeText(username!)

        app.buttons["Continue"].tap()
        
        // Password
        XCTAssertTrue(app.staticTexts["passcode.label"].waitForExistence(timeout: 5.0))
        XCTAssertEqual(app.staticTexts["passcode.label"].label, "Password")
        
        let passwordField = app.secureTextFields["passcode.field"]
        XCTAssertEqual(passwordField.value as? String, "")
        if !passwordField.isFocused {
            passwordField.tap()
        }
        passwordField.typeText(password!)

        app.buttons["Continue"].tap()
        
        // Token
        XCTAssertTrue(app.navigationBars["Token"].waitForExistence(timeout: 5.0))
        XCTAssertFalse(app.staticTexts["No token was found"].exists)
    }

}
