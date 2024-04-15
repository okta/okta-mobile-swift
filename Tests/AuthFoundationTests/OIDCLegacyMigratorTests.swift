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

import XCTest
@testable import TestCommon
@testable import AuthFoundation

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
final class OIDCLegacyMigratorTests: XCTestCase {
    typealias LegacyOIDC = SDKVersion.Migration.LegacyOIDC
    
    var keychain: MockKeychain!
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "my-app:/")!

    override func setUp() {
        keychain = MockKeychain()
        Keychain.implementation = keychain
        
        Credential.tokenStorage = MockTokenStorage()
        Credential.credentialDataSource = MockCredentialDataSource()
    }
    
    override func tearDownWithError() throws {
        Keychain.implementation = KeychainImpl()
        keychain = nil

        SDKVersion.Migration.resetMigrators()
        
        Credential.tokenStorage = CredentialCoordinatorImpl.defaultTokenStorage()
        Credential.credentialDataSource = CredentialCoordinatorImpl.defaultCredentialDataSource()
    }

    func testRegister() throws {
        LegacyOIDC.register(clientId: "clientId")
        
        let migrator = try XCTUnwrap(SDKVersion.Migration.registeredMigrators.first(where: {
            $0 is LegacyOIDC
        }) as? LegacyOIDC)
        
        XCTAssertEqual(migrator.clientId, "clientId")
        XCTAssertNil(migrator.migrationItems)
    }
    
    func testNeedsMigration() throws {
        let migrator = LegacyOIDC(clientId: "clientId")
        
        // Test no credentials to migrate
        keychain.expect(noErr, result: [] as CFArray)
        XCTAssertFalse(migrator.needsMigration)
        keychain.reset()
        
        // Test a non-matching credential
        keychain.expect(noErr, result: [
            [
                "svce": "",
                "acct": "thisdoesnotmatch",
                "class": "genp",
                "cdat": Date(),
                "mdat": Date(),
                "pdmn": "ak",
                "agrp": "com.okta.sample.app"
            ]
        ] as CFArray)
        XCTAssertFalse(migrator.needsMigration)
        
        // Test a matching credential
        keychain.expect(noErr, result: [
            [
                "svce": "",
                "acct": "0oathisistheaccount0",
                "class": "genp",
                "cdat": Date(),
                "mdat": Date(),
                "pdmn": "ak",
                "agrp": "com.okta.sample.app"
            ]
        ] as CFArray)
        XCTAssertTrue(migrator.needsMigration)

        // Test that a clientId match counts as a match
        keychain.expect(noErr, result: [
            [
                "svce": "",
                "acct": "clientId",
                "class": "genp",
                "cdat": Date(),
                "mdat": Date(),
                "pdmn": "ak",
                "agrp": "com.okta.sample.app"
            ]
        ] as CFArray)
        XCTAssertTrue(migrator.needsMigration)
    }

    func testMigrate() throws {
        let notificationRecorder = NotificationRecorder(observing: [ .credentialMigrated ])
        
        let migrator = LegacyOIDC(clientId: "clientId")
        
        // Note: This mock file was generated manually using the okta-oidc-ios package, archived, and base64-encoded.
        let base64Data = try data(from: .module, for: "MockLegacyOIDCKeychainItem.data", in: "MockResponses")
        let base64String = try XCTUnwrap(String(data: base64Data, encoding: .utf8))
            .trimmingCharacters(in: .newlines)
        let oidcData = try XCTUnwrap(Data(base64Encoded: base64String))
        
        keychain.expect(noErr, result: [
            [
                "svce": "",
                "acct": "0oathisistheaccount0",
                "class": "genp",
                "cdat": Date(),
                "mdat": Date(),
                "pdmn": "ak",
                "agrp": "com.okta.sample.app"
            ]
        ] as CFArray)

        keychain.expect(noErr, result: [
            "svce": "",
            "class": "genp",
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "acct": "0oathisistheaccount0",
            "v_Data": oidcData
        ] as CFDictionary)
        
        keychain.expect(noErr)

        XCTAssertNoThrow(try migrator.migrate())
        
        XCTAssertEqual(notificationRecorder.notifications.count, 1)
        
        let credential = try XCTUnwrap(notificationRecorder.notifications.first?.object as? Credential)
        XCTAssertEqual(credential.id, "0oathisistheaccount0")
        XCTAssertEqual(credential.token.refreshToken, "therefreshtoken")
        XCTAssertEqual(credential.token.context.clientSettings?["redirect_uri"], "com.example:/callback")
        XCTAssertEqual(credential.token.context.configuration.baseURL.absoluteString, "https://example.com")
        XCTAssertNotEqual(credential.token.context.configuration.clientId, "0oathisistheaccount0")
    }
}
#endif
