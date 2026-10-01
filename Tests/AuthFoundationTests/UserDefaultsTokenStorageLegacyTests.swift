//
// Copyright (c) 2026-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if !COCOAPODS
import JSON
#endif

@testable import AuthFoundation
@testable import TestCommon

// Unlike `MockKeychain`, `UserDefaults` is a real store, so these tests can assert
// the persisted bytes before and after a read, and that the change outlives the
// storage instance that made it.
final class UserDefaultsTokenStorageLegacyTests: XCTestCase {
    private var userDefaults: UserDefaults!

    private let legacyTokenID = "1834AF8D-BC97-4CCE-876F-300314784D5B"
    private let allTokensKey = "com.okta.authfoundation.allTokens"
    private let defaultTokenKey = "com.okta.authfoundation.defaultToken"

    override func setUp() async throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()

        userDefaults = UserDefaults(suiteName: name)
        userDefaults.removePersistentDomain(forName: name)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: name)
        userDefaults = nil

        JWK.resetToDefault()
        Token.resetToDefault()
    }

    @discardableResult
    private func seedLegacyStore() throws -> Data {
        let legacyToken = try JSONSerialization.jsonObject(
            with: try data(from: .module, for: "token-legacy_v2_full", in: "MockResponses"))
        let stored = try JSONSerialization.data(withJSONObject: [legacyTokenID: legacyToken])

        userDefaults.set(stored, forKey: allTokensKey)
        userDefaults.set(legacyTokenID, forKey: defaultTokenKey)
        return stored
    }

    private func storedTokenObject() throws -> [String: Any] {
        let data = try XCTUnwrap(userDefaults.data(forKey: allTokensKey), "no tokens persisted")
        let all = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(all[legacyTokenID] as? [String: Any],
                             "token \(legacyTokenID) missing from store")
    }

    func testSeededStoreStartsInLegacyFormat() throws {
        try seedLegacyStore()
        XCTAssertTrue(try storedTokenObject()["rawValue"] is String)
    }

    @CredentialActor
    func testReadingLegacyTokenChangesStoredValue() async throws {
        let seeded = try seedLegacyStore()

        let storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        let token = try storage.get(token: legacyTokenID)
        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)

        XCTAssertNotEqual(userDefaults.data(forKey: allTokensKey), seeded)
        XCTAssertTrue(try storedTokenObject()["rawValue"] is [String: Any])
        XCTAssertFalse(try storedTokenObject()["rawValue"] is String)
    }

    @CredentialActor
    func testNormalizedValueIsReadBackByFreshStorage() async throws {
        try seedLegacyStore()

        let first = UserDefaultsTokenStorage(userDefaults: userDefaults)
        let originalToken = try first.get(token: legacyTokenID)
        let afterNormalization = try XCTUnwrap(userDefaults.data(forKey: allTokensKey))

        let second = UserDefaultsTokenStorage(userDefaults: userDefaults)
        let reloaded = try second.get(token: legacyTokenID)

        XCTAssertEqual(reloaded.decodedStorageFormat, .current)
        XCTAssertEqual(userDefaults.data(forKey: allTokensKey), afterNormalization,
                       "an already-normalized store must not be rewritten again")

        XCTAssertEqual(reloaded, originalToken)
        XCTAssertEqual(reloaded.id, originalToken.id)
        XCTAssertEqual(reloaded.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(reloaded.refreshToken, "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC")
        XCTAssertEqual(reloaded.idToken?.rawValue, JWT.mockIDToken)
        XCTAssertEqual(reloaded.deviceSecret, "device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa")
        XCTAssertEqual(reloaded.scope, ["profile", "offline_access", "openid"])
        XCTAssertEqual(reloaded.tokenType, "Bearer")
        XCTAssertEqual(reloaded.expiresIn, 3600)
        XCTAssertEqual(reloaded.json, originalToken.json)
        XCTAssertEqual(reloaded.issuedAt?.timeIntervalSinceReferenceDate,
                       originalToken.issuedAt?.timeIntervalSinceReferenceDate)
    }

    @CredentialActor
    func testCurrentFormatStoreIsNotRewritten() async throws {
        let seed = UserDefaultsTokenStorage(userDefaults: userDefaults)
        try seed.add(token: Token.mockToken(id: "CurrentTokenId"), metadata: nil, security: [])

        let before = try XCTUnwrap(userDefaults.data(forKey: allTokensKey))

        let storage = UserDefaultsTokenStorage(userDefaults: userDefaults)
        _ = try storage.get(token: "CurrentTokenId")

        XCTAssertEqual(userDefaults.data(forKey: allTokensKey), before)
    }
}
