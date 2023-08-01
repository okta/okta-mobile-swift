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

final class TokenTests: XCTestCase {
    let configuration = OAuth2Client.Configuration(baseURL: URL(string: "https://example.com")!,
                                                   clientId: "clientid",
                                                   scopes: "openid")
    
    override func setUpWithError() throws {
        JWK.validator = MockJWKValidator()
        Token.idTokenValidator = MockIDTokenValidator()
        Token.accessTokenValidator = MockTokenHashValidator()
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
                                    clientSettings: [CodingUserInfoKey.apiClientConfiguration: "bar"])
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
        decoder.userInfo = [.apiClientConfiguration: configuration]
        
        let token = try decoder.decode(Token.self, from: data)
        XCTAssertNil(token.scope)
    }
    
    func testToken() throws {
        let token = Token(id: "TokenId",
                          issuedAt: Date(),
                          tokenType: "Bearer",
                          expiresIn: 3600,
                          accessToken: "the_access_token",
                          scope: "openid profile offline_access",
                          refreshToken: "the_refresh_token",
                          idToken: nil,
                          deviceSecret: "the_device_secret",
                          context: Token.Context(configuration: configuration,
                                                 clientSettings: []))
        
        XCTAssertEqual(token.token(of: .accessToken), token.accessToken)
        XCTAssertEqual(token.token(of: .refreshToken), token.refreshToken)
        XCTAssertEqual(token.token(of: .deviceSecret), token.deviceSecret)

        let data = try JSONEncoder().encode(token)
        let decodedToken = try JSONDecoder().decode(Token.self, from: data)
        XCTAssertEqual(token, decodedToken)
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

    func testTokenFromRefreshToken() throws {
        let client = try mockClient()
        
        var tokenResult: Token?
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
        waitForExpectations(timeout: 1)
        
        let token = try XCTUnwrap(tokenResult)
        
        XCTAssertEqual(token.token(of: .accessToken), String.mockAccessToken)
        XCTAssertNotEqual(token.id, Token.RefreshRequest.placeholderId)
    }
    
    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func testTokenFromRefreshTokenAsync() async throws {
        let client = try mockClient()
        let token = try await Token.from(refreshToken: "the_refresh_token", using: client)
        XCTAssertEqual(token.token(of: .accessToken), String.mockAccessToken)
        XCTAssertNotEqual(token.id, Token.RefreshRequest.placeholderId)
    }
    #endif
    
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
        
        return OAuth2Client(baseURL: URL(string: "https://example.com/")!,
                            clientId: "clientId",
                            scopes: "openid profile offline_access",
                            session: urlSession)
    }
}
