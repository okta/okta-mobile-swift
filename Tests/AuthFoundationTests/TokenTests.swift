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

final class TokenTests: XCTestCase {
    let baseURL = URL(string: "https://example.com")!
    
    func testTokenContextNilSettings() throws {
        let context = Token.Context(baseURL: baseURL, clientSettings: nil)
        XCTAssertEqual(context.baseURL, baseURL)
        
        let data = try JSONEncoder().encode(context)
        let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
        XCTAssertEqual(context, decodedContext)
    }
    
    func testTokenContextStringSettings() throws {
        let context = Token.Context(baseURL: baseURL,
                                    clientSettings: ["foo": "bar"])
        XCTAssertEqual(context.clientSettings, ["foo": "bar"])
        
        let data = try JSONEncoder().encode(context)
        let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
        XCTAssertEqual(context, decodedContext)
    }

    func testTokenContextCodingUserInfoKeySettings() throws {
        let context = Token.Context(baseURL: baseURL,
                                    clientSettings: [CodingUserInfoKey.baseURL: "bar"])
        XCTAssertEqual(context.clientSettings, ["baseURL": "bar"])
        
        let data = try JSONEncoder().encode(context)
        let decodedContext = try JSONDecoder().decode(Token.Context.self, from: data)
        XCTAssertEqual(context, decodedContext)
    }
    
    func testToken() throws {
        let token = Token(issuedAt: Date(),
                          tokenType: "Bearer",
                          expiresIn: 3600,
                          accessToken: "the_access_token",
                          scope: "openid profile offline_access",
                          refreshToken: "the_refresh_token",
                          idToken: "the_id_token",
                          deviceSecret: "the_device_secret",
                          context: Token.Context(baseURL: baseURL,
                                                 clientSettings: []))
        
        XCTAssertEqual(token.token(of: .accessToken), token.accessToken)
        XCTAssertEqual(token.token(of: .refreshToken), token.refreshToken)
        XCTAssertEqual(token.token(of: .idToken), token.idToken)
        XCTAssertEqual(token.token(of: .deviceSecret), token.deviceSecret)

        let data = try JSONEncoder().encode(token)
        let decodedToken = try JSONDecoder().decode(Token.self, from: data)
        XCTAssertEqual(token, decodedToken)
    }
}
