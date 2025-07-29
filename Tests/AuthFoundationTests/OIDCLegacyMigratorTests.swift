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
import Testing

@testable import TestCommon
@testable import AuthFoundation

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.10) && os(visionOS))
@Suite("OIDC Legacy Migrator")
struct OIDCLegacyMigratorTests {
    typealias LegacyOIDC = Migration.LegacyOIDC
    
    let issuer = URL(string: "https://example.com")!
    let redirectUri = URL(string: "my-app:/")!

    @Test("Register", .migration, .mockKeychain, .credentialCoordinator)
    func testRegister() throws {
        LegacyOIDC.register(clientId: "clientId")
        
        let migrator = try #require(Migration.shared.registeredMigrators.first(where: {
            $0 is LegacyOIDC
        }) as? LegacyOIDC)
        
        #expect(migrator.clientId == "clientId")
        #expect(migrator.migrationItems == nil)
    }
    
    @Test("Needs migration status check", .migration, .mockKeychain, .credentialCoordinator)
    func testNeedsMigration() throws {
        let keychain = try #require(Test.current?.mockKeychain)
        let migrator = LegacyOIDC(clientId: "clientId")
        
        // Test no credentials to migrate
        keychain.expect(noErr, result: [] as CFArray)
        #expect(!migrator.needsMigration)
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
        #expect(!migrator.needsMigration)
        
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
        #expect(migrator.needsMigration)

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
        #expect(migrator.needsMigration)
    }

    @Test("Migrate", .migration, .mockKeychain, .credentialCoordinator, .notificationCenter)
    func testMigrate() throws {
        let keychain = try #require(Test.current?.mockKeychain)
        let notificationCenter = try #require(Test.current?.notificationCenter)
        let notificationRecorder = NotificationRecorder(center: notificationCenter,
                                                        observing: [.credentialMigrated])
        let migrator = LegacyOIDC(clientId: "clientId")
        
        // Note: This mock file was generated manually using the okta-oidc-ios package, archived, and base64-encoded.
        let base64Data = try data(from: .module, for: "MockLegacyOIDCKeychainItem.data", in: "MockResponses")
        let base64String = try #require(String(data: base64Data, encoding: .utf8))
            .trimmingCharacters(in: .newlines)
        let oidcData = try #require(Data(base64Encoded: base64String))
        
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
        
        try migrator.migrate()
        
        // Need to wait for the async notification dispatch
        usleep(useconds_t(2000))
        
        #expect(notificationRecorder.notifications.count == 1)
        
        let credential = try #require(notificationRecorder.notifications.first?.object as? Credential)
        #expect(credential.id == "0oathisistheaccount0")
        #expect(credential.token.refreshToken == "therefreshtoken")
        #expect(credential.token.context.clientSettings?["redirect_uri"] == "com.example:/callback")
        #expect(credential.token.context.configuration.baseURL.absoluteString == "https://example.com")
        #expect(credential.token.context.configuration.clientId != "0oathisistheaccount0")
    }
}
#endif
