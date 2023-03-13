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
@testable import AuthFoundation

extension Token {
    enum MockOptions {
        case refreshToken
        case deviceSecret
        case idToken
    }

    static let mockConfiguration = OAuth2Client.Configuration(
        baseURL: URL(string: "https://example.com")!,
        clientId: "0oa3en4fIMQ3ddc204w5",
        scopes: "offline_access profile openid")

    static let simpleMockToken = mockToken()
    
    static func mockToken(id: String = "TokenId",
                          refreshToken: String? = "abc123",
                          deviceSecret: String? = nil,
                          issuedOffset: TimeInterval = 0,
                          expiresIn: TimeInterval = 3600) -> Token
    {
        let clientSettings = [ "client_id": mockConfiguration.clientId ]
        
        return Token(id: id,
              issuedAt: Date(timeIntervalSinceNow: -issuedOffset),
              tokenType: "Bearer",
              expiresIn: expiresIn,
              accessToken: JWT.mockAccessToken,
              scope: "openid",
              refreshToken: refreshToken,
              idToken: try? JWT(JWT.mockIDToken),
              deviceSecret: deviceSecret,
              context: .init(configuration: mockConfiguration,
                             clientSettings: clientSettings))
    }
    
    static func token(with options: [MockOptions] = []) -> Token {
        var scopes = "openid"
        
        var refreshToken: String? = nil
        if options.contains(.refreshToken) {
            refreshToken = "refresh123"
            scopes += " offline_access"
        }
        
        var deviceSecret: String? = nil
        if options.contains(.deviceSecret) {
            deviceSecret = "device123"
            scopes += " device_sso"
        }
        
        var idToken: JWT? = nil
        if options.contains(.idToken) {
            idToken = try! JWT(JWT.mockIDToken)
        }
        
        return Token(id: "TokenId",
                     issuedAt: Date(),
                     tokenType: "Bearer",
                     expiresIn: 300,
                     accessToken: JWT.mockAccessToken,
                     scope: scopes,
                     refreshToken: refreshToken,
                     idToken: idToken,
                     deviceSecret: deviceSecret,
                     context: Token.Context(configuration: .init(baseURL: URL(string: "https://example.com/oauth2/default")!,
                                                                 clientId: "clientid",
                                                                 scopes: scopes),
                                            clientSettings: [ "client_id": "clientid" ]))
    }

}
