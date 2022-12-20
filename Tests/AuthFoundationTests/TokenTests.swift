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
}
