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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || (swift(>=5.10) && os(visionOS))

import XCTest

#if !COCOAPODS
import JSON
#endif

@testable import AuthFoundation
@testable import TestCommon

final class KeychainTokenStorageLegacyTests: XCTestCase {
    var mock: MockKeychain!
    var storage: KeychainTokenStorage!

    private let legacyTokenID = "1834AF8D-BC97-4CCE-876F-300314784D5B"

    override func setUp() async throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()

        mock = MockKeychain()
        Keychain.implementation.wrappedValue = mock
        storage = await KeychainTokenStorage()
    }

    override func tearDownWithError() throws {
        Keychain.resetToDefault()
        JWK.resetToDefault()
        Token.resetToDefault()
        mock = nil
        storage = nil
    }

    private func legacyFixture() throws -> Data {
        try data(from: .module, for: "token-legacy_v2_full", in: "MockResponses")
    }

    private func keychainResult(account: String, value: Data) -> CFDictionary {
        [
            "tomb": 0,
            "svce": KeychainTokenStorage.serviceName,
            "musr": nil,
            "class": "genp",
            "sync": 0,
            "cdat": Date(),
            "mdat": Date(),
            "pdmn": "ak",
            "agrp": "com.okta.sample.app",
            "acct": account,
            "sha": "someshadata".data(using: .utf8),
            "UUID": UUID().uuidString,
            "v_Data": value,
        ] as CFDictionary
    }

    func testGetLegacyTokenSucceeds() async throws {
        mock.expect(errSecSuccess, result: keychainResult(account: legacyTokenID,
                                                          value: try legacyFixture()))
        mock.expect(noErr)

        let token = try await storage.get(token: legacyTokenID)

        XCTAssertEqual(token.id, legacyTokenID)
        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token.refreshToken, "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC")
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.expiresIn, 3600)
    }

    func testGetLegacyTokenNormalizesStoredItem() async throws {
        mock.expect(errSecSuccess, result: keychainResult(account: legacyTokenID,
                                                          value: try legacyFixture()))
        mock.expect(noErr)

        let token = try await storage.get(token: legacyTokenID)

        let update = try XCTUnwrap(mock.operations.first(where: { $0.action == .update }),
                                   "expected the legacy item to be rewritten")
        let written = try XCTUnwrap(update.attributes?["v_Data"] as? Data)

        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: written) as? [String: Any])
        XCTAssertTrue(object["rawValue"] is [String: Any])
        XCTAssertFalse(object["rawValue"] is String)

        let reRead = try JSONDecoder().decode(Token.self, from: written)
        XCTAssertEqual(reRead, token)
        XCTAssertEqual(reRead.id, token.id)
        XCTAssertEqual(reRead.accessToken, token.accessToken)
        XCTAssertEqual(reRead.json, token.json)
        XCTAssertEqual(reRead.decodedStorageFormat, .current)

        XCTAssertEqual(update.query["acct"] as? String, legacyTokenID)
        XCTAssertEqual(update.query["svce"] as? String, KeychainTokenStorage.serviceName)
    }

    // Note: `MockKeychain` replays canned results rather than persisting writes, so the
    //       bytes written during normalization are fed back in as the stored value to
    //       confirm a later read observes them.
    func testStoredValueConvergesAfterNormalization() async throws {
        mock.expect(errSecSuccess, result: keychainResult(account: legacyTokenID,
                                                          value: try legacyFixture()))
        mock.expect(noErr)

        let firstRead = try await storage.get(token: legacyTokenID)

        let update = try XCTUnwrap(mock.operations.first(where: { $0.action == .update }))
        let normalizedValue = try XCTUnwrap(update.attributes?["v_Data"] as? Data)
        XCTAssertNotEqual(normalizedValue, try legacyFixture())

        mock.reset()
        mock.expect(errSecSuccess, result: keychainResult(account: legacyTokenID,
                                                          value: normalizedValue))

        let secondRead = try await storage.get(token: legacyTokenID)

        XCTAssertEqual(secondRead.decodedStorageFormat, .current)
        XCTAssertNil(mock.operations.first(where: { $0.action == .update }),
                     "an already-normalized item must not be rewritten again")

        XCTAssertEqual(secondRead, firstRead)
        XCTAssertEqual(secondRead.id, firstRead.id)
        XCTAssertEqual(secondRead.accessToken, firstRead.accessToken)
        XCTAssertEqual(secondRead.refreshToken, firstRead.refreshToken)
        XCTAssertEqual(secondRead.idToken?.rawValue, firstRead.idToken?.rawValue)
        XCTAssertEqual(secondRead.deviceSecret, firstRead.deviceSecret)
        XCTAssertEqual(secondRead.scope, firstRead.scope)
        XCTAssertEqual(secondRead.expiresIn, firstRead.expiresIn)
        XCTAssertEqual(secondRead.json, firstRead.json)
        XCTAssertEqual(secondRead.issuedAt?.timeIntervalSinceReferenceDate,
                       firstRead.issuedAt?.timeIntervalSinceReferenceDate)
    }

    func testGetCurrentFormatTokenDoesNotRewriteItem() async throws {
        let current = try JSONEncoder().encode(Token.mockToken(id: "CurrentTokenId"))
        mock.expect(errSecSuccess, result: keychainResult(account: "CurrentTokenId",
                                                          value: current))

        _ = try await storage.get(token: "CurrentTokenId")

        XCTAssertNil(mock.operations.first(where: { $0.action == .update }))
    }

    func testGetLegacyTokenSucceedsEvenIfNormalizationFails() async throws {
        mock.expect(errSecSuccess, result: keychainResult(account: legacyTokenID,
                                                          value: try legacyFixture()))
        mock.expect(errSecAuthFailed)

        let token = try await storage.get(token: legacyTokenID)

        XCTAssertEqual(token.id, legacyTokenID)
        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)
    }
}

#endif
