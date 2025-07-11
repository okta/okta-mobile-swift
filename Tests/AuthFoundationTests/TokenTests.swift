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
@testable import AuthFoundation
@testable import TestCommon

fileprivate struct MockTokenRequest: OAuth2TokenRequest, IDTokenValidatorContext {
    var nonce: String?
    var maxAge: TimeInterval?
    let context: (any AuthenticationContext)? = nil
    let openIdConfiguration: OpenIdConfiguration
    let clientConfiguration: OAuth2Client.Configuration
    let url: URL
    let category = OAuth2APIRequestCategory.token
    var tokenValidatorContext: any IDTokenValidatorContext { self }
    var bodyParameters: [String: any APIRequestArgument]?
}

final class TokenTests: XCTestCase {
    var openIdConfiguration: OpenIdConfiguration!
    let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scope: "openid")
    
    override func setUpWithError() throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        
        openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: .module,
                           for: "openid-configuration",
                           in: "MockResponses"))
    }
    
    override func tearDownWithError() throws {
        JWK.resetToDefault()
        Token.resetToDefault()
    }
    
    func testTokenContextNilSettings() throws {
        let context = Token.Context(configuration: configuration, clientSettings: nil)
        XCTAssertEqual(context.configuration, configuration)
        
        let data = try JSONEncoder().encode(context)
        let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
        XCTAssertEqual(context, decodedContext)
    }
    
    func testTokenContextStringSettings() throws {
        let context = Token.Context(configuration: configuration,
                                    clientSettings: ["foo": "bar"])
        XCTAssertEqual(context.clientSettings, ["foo": "bar"])
        
        let data = try JSONEncoder().encode(context)
        let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
        XCTAssertEqual(context, decodedContext)
    }

    func testTokenContextCodingUserInfoKeySettings() throws {
        let context = Token.Context(configuration: configuration,
                                    clientSettings: [
                                        CodingUserInfoKey.apiClientConfiguration: "bar",
                                    ])
        XCTAssertEqual(context.clientSettings, ["apiClientConfiguration": "bar"])
        
        let data = try JSONEncoder().encode(context)
        let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
        XCTAssertEqual(context, decodedContext)
    }
    
    func testNilScope() throws {
        let data = data(for: """
        {
           "token_type": "Bearer",
           "expires_in": 3600,
           "access_token": "\(JWT.mockAccessToken)"
         }
        """)
        
        let decoder = defaultJSONDecoder
        decoder.userInfo = [
            .apiClientConfiguration: configuration,
        ]
        
        let token = try decoder.decode(Token.self, from: data)
        XCTAssertNil(token.scope)
    }
    
    func testToken() throws {
        let token = try! Token(id: "TokenId",
                               issuedAt: Date(),
                               tokenType: "Bearer",
                               expiresIn: 3600,
                               accessToken: "the_access_token",
                               scope: "openid profile offline_access",
                               refreshToken: "the_refresh_token",
                               idToken: nil,
                               deviceSecret: "the_device_secret",
                               context: Token.Context(configuration: configuration,
                                                      clientSettings: [:]))
        
        XCTAssertEqual(token.token(of: .accessToken), token.accessToken)
        XCTAssertEqual(token.token(of: .refreshToken), token.refreshToken)
        XCTAssertEqual(token.token(of: .deviceSecret), token.deviceSecret)

        let data = try JSONEncoder().encode(token)
        let decodedToken = try JSONDecoder().decode(Token.self, from: data)
        XCTAssertEqual(token, decodedToken)
    }

    func testTokenNilContext() throws {
        let decoder = defaultJSONDecoder
        decoder.userInfo = [:]
        
        XCTAssertThrowsError(try decoder.decode(Token.self,
                                                from: try data(from: .module,
                                                               for: "token",
                                                               in: "MockResponses")))
    }
    
    func testMFAAttestationToken() throws {
        let decoder = defaultJSONDecoder
        decoder.userInfo = [
            .apiClientConfiguration: configuration,
            .clientSettings: [
                "acr_values": "urn:okta:app:mfa:attestation"
            ]
        ]
        
        let token = try decoder.decode(Token.self,
                                       from: try data(from: .module,
                                                      for: "token-mfa_attestation",
                                                      in: "MockResponses"))
        XCTAssertTrue(token.accessToken.isEmpty)
    }
    
    func testMFAAttestationTokenFailed() throws {
        let decoder = defaultJSONDecoder
        decoder.userInfo = [
            .apiClientConfiguration: configuration,
        ]
        
        XCTAssertThrowsError(try decoder.decode(Token.self,
                                                from: try data(from: .module,
                                                               for: "token-no_access_token",
                                                               in: "MockResponses")))
    }
    
    func testTokenEquality() throws {
        var token1 = Token.mockToken()
        var token2 = Token.mockToken()
        
        XCTAssertEqual(token1, token2)
        
        token2 = Token.mockToken(refreshToken: "SomethingDifferent")
        XCTAssertNotEqual(token1, token2)
        
        token1 = Token.mockToken(deviceSecret: "First")
        token2 = Token.mockToken(deviceSecret: "Second")
        XCTAssertNotEqual(token1, token2)
    }

    func testTokenFromRefreshToken() async throws {
        let client = try mockClient()
        
        nonisolated(unsafe) var tokenResult: Token?
        let wait = expectation(description: "Token exchange")
        Token.from(refreshToken: "the_refresh_token", using: client) { result in
            switch result {
            case .success(let success):
                tokenResult = success
            case .failure(let failure):
                XCTAssertNil(failure)
            }
            wait.fulfill()
        }
        await fulfillment(of: [wait], timeout: .standard)

        let token = try XCTUnwrap(tokenResult)
        
        XCTAssertEqual(token.token(of: .accessToken), String.mockAccessToken)
        XCTAssertNotEqual(token.id, Token.RefreshRequest.placeholderId)
    }
    
    func testTokenFromV1Data() throws {
        // Note: The following is a redacted version of the raw payload saved to
        //       the keychain from a version of the SDK where the V1 coding keys
        //       were used. This is to ensure mimgration works as expected.
        let storedData = """
            {"scope":"profile offline_access openid","context":{"configuration":{"scopes":"openid profile offline_access","baseURL":"https://example.com/oauth2/default","clientId":"0oatheclientid","authentication":{"none":{}},"discoveryURL":"https://example.com/oauth2/default/.well-known/openid-configuration"},"clientSettings":{"client_id":"0oatheclientid","scope":"openid profile offline_access","redirect_uri":"com.example:/callback"}},"accessToken":"\(JWT.mockAccessToken)","tokenType":"Bearer","idToken":"\(JWT.mockIDToken)","id":"1834AF8D-BC97-4CCE-876F-300314784D5B","expiresIn":3600,"refreshToken":"refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC","deviceSecret":"device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa","issuedAt":744576826.0011461}
            """
        let data = try XCTUnwrap(storedData.data(using: .utf8))
        
        let token = try JSONDecoder().decode(Token.self, from: data)
        XCTAssertEqual(token.id, "1834AF8D-BC97-4CCE-876F-300314784D5B")
        XCTAssertEqual(token.accessToken, JWT.mockAccessToken)
        XCTAssertEqual(token.idToken?.rawValue, JWT.mockIDToken)
        XCTAssertEqual(token.scope, ["profile", "offline_access", "openid"])
        XCTAssertEqual(token.expiresIn, 3600)
        XCTAssertEqual(token.refreshToken, "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC")
        XCTAssertEqual(token.deviceSecret, "device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa")
        XCTAssertEqual(token.issuedAt?.timeIntervalSinceReferenceDate, 744576826.0011461)
        XCTAssertEqual(token.context.configuration.scope, ["openid", "profile", "offline_access"])
        XCTAssertEqual(token.context.configuration.redirectUri?.absoluteString, "com.example:/callback")
        XCTAssertEqual(token.context, .init(configuration: .init(issuerURL: try XCTUnwrap(URL(string: "https://example.com/oauth2/default")),
                                                                 clientId: "0oatheclientid",
                                                                 scope: ["openid", "profile", "offline_access"],
                                                                 redirectUri: URL(string: "com.example:/callback"),
                                                                 authentication: .none),
                                            clientSettings: nil))
        XCTAssertEqual(token.jsonPayload.jsonValue, try JSON([
            "scope": "profile offline_access openid",
            "access_token": JWT.mockAccessToken,
            "token_type": "Bearer",
            "id_token": JWT.mockIDToken,
            "expires_in": 3600,
            "refresh_token": "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC",
            "device_secret":"device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa",
        ]))
    }
    
    func testTokenClaims() throws {
        var token: Token!
        
        token = try! Token(id: "TokenId",
                           issuedAt: Date(),
                           tokenType: "Bearer",
                           expiresIn: 3600,
                           accessToken: "the_access_token",
                           scope: "openid profile offline_access",
                           refreshToken: "the_refresh_token",
                           idToken: nil,
                           deviceSecret: "the_device_secret",
                           context: Token.Context(configuration: configuration,
                                                  clientSettings: [:]))
        XCTAssertEqual(token.allClaims.sorted(), [
            "expires_in",
            "token_type",
            "access_token",
            "scope",
            "refresh_token",
            "device_secret",
        ].sorted())
        XCTAssertEqual(token[.accessToken], "the_access_token")
    }
    
    func testTokenFromRefreshTokenAsync() async throws {
        let client = try mockClient()
        let token = try await Token.from(refreshToken: "the_refresh_token", using: client)
        XCTAssertEqual(token.token(of: .accessToken), String.mockAccessToken)
        XCTAssertNotEqual(token.id, Token.RefreshRequest.placeholderId)
    }
    
    func mockClient() throws -> OAuth2Client {
        let urlSession = URLSessionMock()
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: .module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: .module, for: "keys", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/token",
                          data: data(for: """
            {
               "token_type": "Bearer",
               "expires_in": 3000,
               "access_token": "\(String.mockAccessToken)",
               "scope": "openid profile offline_access",
               "refresh_token": "therefreshtoken",
               "id_token": "\(String.mockIdToken)"
             }
            """))
        
        return OAuth2Client(issuerURL: URL(string: "https://example.com/")!,
                            clientId: "clientId",
                            scope: "openid profile offline_access",
                            session: urlSession)
    }
}
