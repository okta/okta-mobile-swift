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

@Suite("Token Management and JWT Validation", .disabled("Debugging test deadlocks within CI"))
struct TokenTests {
    let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scope: "openid")
    
    func withTokenTestEnvironment<T>(_ test: (OpenIdConfiguration) throws -> T) throws -> T {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
        
        defer {
            JWK.resetToDefault()
            Token.resetToDefault()
        }
        
        let openIdConfiguration = try OpenIdConfiguration.jsonDecoder.decode(
            OpenIdConfiguration.self,
            from: try data(from: Bundle.module,
                           for: "openid-configuration",
                           in: "MockResponses"))
        
        return try test(openIdConfiguration)
    }
    
    @Test("Token context serialization with nil client settings")
    func testTokenContextNilSettings() throws {
        try withTokenTestEnvironment { _ in
            let context = Token.Context(configuration: configuration, clientSettings: nil)
            #expect(context.configuration == configuration)
            
            let data = try JSONEncoder().encode(context)
            let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
            #expect(context == decodedContext)
        }
    }
    
    @Test("Token context serialization with string client settings")
    func testTokenContextStringSettings() throws {
        try withTokenTestEnvironment { _ in
            let context = Token.Context(configuration: configuration,
                                        clientSettings: ["foo": "bar"])
            #expect(context.clientSettings == ["foo": "bar"])
            
            let data = try JSONEncoder().encode(context)
            let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
            #expect(context == decodedContext)
        }
    }

    @Test("Token context with CodingUserInfoKey settings")
    func testTokenContextCodingUserInfoKeySettings() throws {
        try withTokenTestEnvironment { _ in
            let context = Token.Context(configuration: configuration,
                                        clientSettings: [
                                            CodingUserInfoKey.apiClientConfiguration: "bar",
                                        ])
            #expect(context.clientSettings == ["apiClientConfiguration": "bar"])
            
            let data = try JSONEncoder().encode(context)
            let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
            #expect(context == decodedContext)
        }
    }
    
    @Test("Token decoding with nil scope")
    func testNilScope() throws {
        try withTokenTestEnvironment { _ in
            let testData = data(for: """
            {
               "token_type": "Bearer",
               "expires_in": 3600,
               "access_token": "\(JWT.mockAccessToken)"
             }
            """)
            
            let decoder = defaultJSONDecoder()
            decoder.userInfo = [
                .apiClientConfiguration: configuration,
            ]
            
            let token = try decoder.decode(Token.self, from: testData)
            #expect(token.scope == nil)
        }
    }
    
    @Test("Token creation and property access")
    func testToken() throws {
        try withTokenTestEnvironment { _ in
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
            
            #expect(token.token(of: .accessToken) == token.accessToken)
            #expect(token.token(of: .refreshToken) == token.refreshToken)
            #expect(token.token(of: .deviceSecret) == token.deviceSecret)

            let tokenData = try JSONEncoder().encode(token)
            let decodedToken = try JSONDecoder().decode(Token.self, from: tokenData)
            #expect(token == decodedToken)
        }
    }

    @Test("Token decoding with nil context throws error")
    func testTokenNilContext() throws {
        let decoder = defaultJSONDecoder()
        
        #expect(throws: (any Error).self) {
            try decoder.decode(Token.self,
                               from: try data(from: .module,
                                              for: "token",
                                              in: "MockResponses"))
        }
    }
    
    @Test("MFA attestation token handling")
    func testMFAAttestationToken() throws {
        let decoder = defaultJSONDecoder()
        decoder.userInfo = [
            .apiClientConfiguration: configuration,
            .clientSettings: [
                "acr_values": "urn:okta:app:mfa:attestation"
            ]
        ]
        
        let token = try decoder.decode(Token.self,
                                       from: try data(from: Bundle.module,
                                                    for: "token-mfa_attestation",
                                                    in: "MockResponses"))
        #expect(token.accessToken.isEmpty)
    }
    
    @Test("MFA attestation token failure without proper configuration")
    func testMFAAttestationTokenFailed() throws {
        let decoder = defaultJSONDecoder()
        decoder.userInfo = [
            .apiClientConfiguration: configuration,
        ]
        
        #expect(throws: (any Error).self) {
            try decoder.decode(Token.self,
                             from: try data(from: Bundle.module,
                                          for: "token-no_access_token",
                                          in: "MockResponses"))
        }
    }
    
    @Test("Token equality comparison with different properties")
    func testTokenEquality() throws {
        try withTokenTestEnvironment { _ in
            var token1 = Token.mockToken()
            var token2 = Token.mockToken()
            
            #expect(token1 == token2)
            
            token2 = Token.mockToken(refreshToken: "SomethingDifferent")
            #expect(token1 != token2)
            
            token1 = Token.mockToken(deviceSecret: "First")
            token2 = Token.mockToken(deviceSecret: "Second")
            #expect(token1 != token2)
        }
    }

    @Test("Token creation from refresh token using callback API", .mockTokenValidator, .mockJWKValidator)
    func testTokenFromRefreshToken() async throws {
        let client = try mockClient()
        
        let tokenResult = await withCheckedContinuation { continuation in
            Token.from(refreshToken: "the_refresh_token", using: client) { result in
                continuation.resume(returning: result)
            }
        }
        
        let token = try tokenResult.get()
        #expect(token.token(of: .accessToken) == String.mockAccessToken)
        #expect(token.id != Token.RefreshRequest.placeholderId)
    }
    
    @Test("Token decoding from V1 data format")
    func testTokenFromV1Data() throws {
        // Note: The following is a redacted version of the raw payload saved to
        //       the keychain from a version of the SDK where the V1 coding keys
        //       were used. This is to ensure mimgration works as expected.
        let storedData = """
            {"scope":"profile offline_access openid","context":{"configuration":{"scopes":"openid profile offline_access","baseURL":"https://example.com/oauth2/default","clientId":"0oatheclientid","authentication":{"none":{}},"discoveryURL":"https://example.com/oauth2/default/.well-known/openid-configuration"},"clientSettings":{"client_id":"0oatheclientid","scope":"openid profile offline_access","redirect_uri":"com.example:/callback"}},"accessToken":"\(JWT.mockAccessToken)","tokenType":"Bearer","idToken":"\(JWT.mockIDToken)","id":"1834AF8D-BC97-4CCE-876F-300314784D5B","expiresIn":3600,"refreshToken":"refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC","deviceSecret":"device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa","issuedAt":744576826.0011461}
            """
        let data = try #require(storedData.data(using: .utf8))
        
        let token = try JSONDecoder().decode(Token.self, from: data)
        #expect(token.id == "1834AF8D-BC97-4CCE-876F-300314784D5B")
        #expect(token.accessToken == JWT.mockAccessToken)
        #expect(token.idToken?.rawValue == JWT.mockIDToken)
        #expect(token.scope == ["profile", "offline_access", "openid"])
        #expect(token.expiresIn == 3600)
        #expect(token.refreshToken == "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC")
        #expect(token.deviceSecret == "device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa")
        #expect(token.issuedAt?.timeIntervalSinceReferenceDate == 744576826.0011461)
        #expect(token.context.configuration.scope == ["openid", "profile", "offline_access"])
        #expect(token.context.configuration.redirectUri?.absoluteString == "com.example:/callback")
        let expectedContext = Token.Context(
            configuration: OAuth2Client.Configuration(
                issuerURL: try #require(URL(string: "https://example.com/oauth2/default")),
                clientId: "0oatheclientid",
                scope: ["openid", "profile", "offline_access"],
                redirectUri: URL(string: "com.example:/callback"),
                authentication: .none
            ),
            clientSettings: nil
        )
        #expect(token.context == expectedContext)
        let expectedJSON = try JSON([
            "scope": "profile offline_access openid",
            "access_token": JWT.mockAccessToken,
            "token_type": "Bearer",
            "id_token": JWT.mockIDToken,
            "expires_in": 3600,
            "refresh_token": "refresh-kl2QWaYgyHaLkCdc6exjsowP9KUTW1ilAWC",
            "device_secret":"device_lh4nMHgcUWLJIVgkcbQwnnSI2F8JMwNshLoa",
        ])
        #expect(token.jsonPayload.jsonValue == expectedJSON)
    }
    
    @Test("Token claims access and enumeration")
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
        #expect(token.allClaims.sorted() == [
            "expires_in",
            "token_type",
            "access_token",
            "scope",
            "refresh_token",
            "device_secret",
        ].sorted())
        let accessTokenValue: String? = token[.accessToken]
        #expect(accessTokenValue == "the_access_token")
    }
    
    @Test("Token creation from refresh token using async API", .mockTokenValidator, .mockJWKValidator)
    func testTokenFromRefreshTokenAsync() async throws {
        let client = try mockClient()
        let token = try await Token.from(refreshToken: "the_refresh_token", using: client)
        #expect(token.token(of: .accessToken) == String.mockAccessToken)
        #expect(token.id != Token.RefreshRequest.placeholderId)
    }
    
    func mockClient() throws -> OAuth2Client {
        let urlSession = URLSessionMock()
        urlSession.expect("https://example.com/.well-known/openid-configuration",
                          data: try data(from: Bundle.module, for: "openid-configuration", in: "MockResponses"),
                          contentType: "application/json")
        urlSession.expect("https://example.com/oauth2/v1/keys?client_id=clientId",
                          data: try data(from: Bundle.module, for: "keys", in: "MockResponses"),
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
