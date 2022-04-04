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
    static let mockContext = Token.Context(
        configuration: OAuth2Client.Configuration(
            baseURL: URL(string: "https://example.com")!,
            clientId: "0oa3en4fIMQ3ddc204w5",
            scopes: "offline_access profile openid"),
        clientSettings: [ "client_id": "0oa3en4fIMQ3ddc204w5" ])

    static let simpleMockToken = mockToken()
    
    static func mockToken(issuedOffset: TimeInterval = 0, expiresIn: TimeInterval = 3600) -> Token {
        Token(id: UUID(),
              issuedAt: Date(timeIntervalSinceNow: -issuedOffset),
              tokenType: "Bearer",
              expiresIn: expiresIn,
              accessToken: JWT.mockAccessToken,
              scope: "openid",
              refreshToken: nil,
              idToken: try? JWT(JWT.mockIDToken),
              deviceSecret: nil,
              context: mockContext)
    }
}
