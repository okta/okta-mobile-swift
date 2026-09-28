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

final class TokenLegacyStorageTests: XCTestCase {
    // The `token-legacy_v2_*` fixtures were produced by running
    // `JSONEncoder().encode(token)` against a checkout of tag 2.1.4, which
    // encoded the claim payload to `rawValue` as a JSON string rather than the
    // object used today. They are byte-for-byte what an upgrading client finds
    // in its keychain.
    override func setUpWithError() throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
    }

    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }

    private func storageDecoder() -> JSONDecoder {
        JSONDecoder()
    }

    private func legacyFixture(_ name: String) throws -> Data {
        try data(from: .module, for: name, in: "MockResponses")
    }

    private func legacyPayload(rawValue: String) throws -> Data {
        var object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try legacyFixture("token-legacy_v2_full")) as? [String: Any])
        object["rawValue"] = rawValue
        return try JSONSerialization.data(withJSONObject: object)
    }

    func testFixturesUseStringEncodedRawValue() throws {
        for name in ["token-legacy_v2_full",
                     "token-legacy_v2_minimal",
                     "token-legacy_v2_mfa_attestation"] {
            let object = try XCTUnwrap(
                try JSONSerialization.jsonObject(with: try legacyFixture(name)) as? [String: Any],
                "\(name) is not a JSON object")
            XCTAssertTrue(object["rawValue"] is String, "\(name): expected a string payload")
            XCTAssertNotNil(object["id"], "\(name): expected V2 `id` key")
            XCTAssertNotNil(object["context"], "\(name): expected V2 `context` key")
        }
    }

    func testCurrentFormatUsesObjectEncodedRawValue() throws {
        let data = try JSONEncoder().encode(Token.mockToken())
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue(object["rawValue"] is [String: Any])
    }

    func testDecodeLegacyFullToken() throws {
        let token = try storageDecoder().decode(Token.self,
                                                from: try legacyFixture("token-legacy_v2_full"))

        XCTAssertEqual(token.id, "1834AF8D-BC97-4CCE-876F-300314784D5B")
        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token.idToken?.rawValue, JWT.mockIDToken)
        XCTAssertEqual(token.refreshToken, "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC")
        XCTAssertEqual(token.deviceSecret, "device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa")
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.expiresIn, 3600)
        XCTAssertEqual(token.scope, ["profile", "offline_access", "openid"])
        XCTAssertEqual(token.issuedAt?.timeIntervalSinceReferenceDate, 744576826.0011461)
        XCTAssertNotNil(token.json.value.object)
        XCTAssertEqual(token.json, try JSON([
            "scope": "profile offline_access openid",
            "access_token": JWT.mockAccessToken,
            "token_type": "Bearer",
            "id_token": JWT.mockIDToken,
            "expires_in": 3600,
            "refresh_token": "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC",
            "device_secret": "device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa",
        ]))
        XCTAssertEqual(token.context.configuration.clientId, "0oatheclientid")
        XCTAssertEqual(token.context.configuration.scope, ["openid", "profile", "offline_access"])
        XCTAssertEqual(token.context.configuration.redirectUri?.absoluteString, "com.example:/callback")
    }

    func testDecodeLegacyMinimalToken() throws {
        let token = try storageDecoder().decode(Token.self,
                                                from: try legacyFixture("token-legacy_v2_minimal"))

        XCTAssertEqual(token.id, "MinimalTokenId")
        XCTAssertEqual(token.accessToken, "minimal_access_token")
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.expiresIn, 3600)
        XCTAssertNil(token.refreshToken)
        XCTAssertNil(token.idToken)
        XCTAssertNil(token.deviceSecret)
        XCTAssertNil(token.scope)
    }

    // MFA attestation tokens carry `"access_token": null` and rely on the
    // `acr_values` client setting, so they reach a different branch of
    // `Token.init(id:issuedAt:context:json:)` and fail on `token_type`
    // rather than `access_token` when the payload cannot be read.
    func testDecodeLegacyMFAAttestationToken() throws {
        let token = try storageDecoder().decode(Token.self,
                                                from: try legacyFixture("token-legacy_v2_mfa_attestation"))

        XCTAssertEqual(token.id, "813C2619-9F08-4FF5-9CEC-BCD70D675B6D")
        XCTAssertTrue(token.accessToken.isEmpty)
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.scope, ["openid"])
        XCTAssertNotNil(token.idToken)
    }

    func testReEncodingLegacyTokenEmitsCurrentFormat() throws {
        let token = try storageDecoder().decode(Token.self,
                                                from: try legacyFixture("token-legacy_v2_full"))

        let reEncoded = try JSONEncoder().encode(token)
        let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: reEncoded) as? [String: Any])
        XCTAssertTrue(object["rawValue"] is [String: Any])
        XCTAssertFalse(object["rawValue"] is String)

        let roundTripped = try storageDecoder().decode(Token.self, from: reEncoded)
        XCTAssertEqual(roundTripped, token)
        XCTAssertEqual(roundTripped.id, token.id)
        XCTAssertEqual(roundTripped.accessToken, token.accessToken)
        XCTAssertEqual(roundTripped.json, token.json)
        XCTAssertEqual(roundTripped.issuedAt?.timeIntervalSinceReferenceDate,
                       token.issuedAt?.timeIntervalSinceReferenceDate)
    }

    func testDecodedStorageFormatIsReported() throws {
        let legacy = try storageDecoder().decode(Token.self,
                                                 from: try legacyFixture("token-legacy_v2_full"))
        XCTAssertEqual(legacy.decodedStorageFormat, .legacyStringPayload)
        XCTAssertTrue(legacy.decodedStorageFormat.needsNormalization)

        let current = try storageDecoder().decode(Token.self,
                                                  from: try JSONEncoder().encode(Token.mockToken()))
        XCTAssertEqual(current.decodedStorageFormat, .current)
        XCTAssertFalse(current.decodedStorageFormat.needsNormalization)
    }

    func testV1FormatStillDecodes() throws {
        let storedData = """
            {"scope":"profile offline_access openid","context":{"configuration":{"scopes":"openid profile offline_access","baseURL":"https://example.com/oauth2/default","clientId":"0oatheclientid","authentication":{"none":{}},"discoveryURL":"https://example.com/oauth2/default/.well-known/openid-configuration"},"clientSettings":{"client_id":"0oatheclientid","scope":"openid profile offline_access","redirect_uri":"com.example:/callback"}},"accessToken":"\(JWT.mockAccessToken)","tokenType":"Bearer","idToken":"\(JWT.mockIDToken)","id":"1834AF8D-BC97-4CCE-876F-300314784D5B","expiresIn":3600,"refreshToken":"refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC","deviceSecret":"device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa","issuedAt":744576826.0011461}
            """
        let token = try storageDecoder().decode(Token.self,
                                                from: try XCTUnwrap(storedData.data(using: .utf8)))

        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token.expiresIn, 3600)
        XCTAssertEqual(token.decodedStorageFormat, .v1)
        XCTAssertTrue(token.decodedStorageFormat.needsNormalization)
    }

    func testBareTokenResponseStillDecodes() throws {
        let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                      clientId: "clientid",
                                                      scope: "openid")
        let decoder = storageDecoder()
        decoder.userInfo = [.apiClientConfiguration: configuration]

        let token = try decoder.decode(Token.self, from: data(for: """
            {
               "token_type": "Bearer",
               "expires_in": 3600,
               "access_token": "\(JWT.mockAccessToken)"
             }
            """))
        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token.decodedStorageFormat, .current)
    }

    func testLegacyRawValueWithUnparseableStringThrows() throws {
        XCTAssertThrowsError(try storageDecoder().decode(
            Token.self,
            from: try legacyPayload(rawValue: "this is not json")))
    }

    func testLegacyRawValueWithNonObjectJSONThrows() throws {
        for rawValue in ["[1,2,3]", "[]"] {
            XCTAssertThrowsError(try storageDecoder().decode(
                Token.self,
                from: try legacyPayload(rawValue: rawValue)),
                                 "expected failure for rawValue \(rawValue)")
        }
    }

    func testLegacyRawValueWithEmptyObjectThrows() throws {
        let data = try legacyPayload(rawValue: "{}")
        XCTAssertThrowsError(try storageDecoder().decode(Token.self, from: data)) { error in
            guard case .missingRequiredValue(let key) = error as? ClaimError else {
                return XCTFail("expected ClaimError.missingRequiredValue, got \(error)")
            }
            XCTAssertEqual(key, Token.TokenClaim.accessToken.rawValue)
        }
    }
}
