//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension Token {
    public convenience init(from decoder: Decoder) throws {
        // Initialize defaults supplied from the decoder's userInfo dictionary
        var id: String = decoder.userInfo[.tokenId] as? String ?? UUID().uuidString
        var issuedAt: Date = Date.nowCoordinated
        var context: Context? = decoder.userInfo[.tokenContext] as? Token.Context

        var json: AnyJSON
        
        // Initialize defaults supplied from the decoder's userInfo dictionary
        if let userInfoId = decoder.userInfo[.tokenId] as? String {
            id = userInfoId
        }
        
        if let configuration = decoder.userInfo[.apiClientConfiguration] as? OAuth2Client.Configuration {
            context = Context(configuration: configuration,
                              clientSettings: decoder.userInfo[.clientSettings])
        }
        
        
        // Attempt to decode V1 token data
        if let container = try? decoder.container(keyedBy: CodingKeysV1.self),
           [.id, .accessToken].allSatisfy(container.allKeys.contains)
        {
            if container.contains(.context) {
                context = try container.decode(Context.self, forKey: .context)
            }

            if container.contains(.id) {
                id = try container.decode(String.self, forKey: .id)
            }
            
            if container.contains(.issuedAt) {
                issuedAt = try container.decode(Date.self, forKey: .issuedAt)
            }

            var payload: [TokenClaim: Any] = [
                .accessToken: try container.decode(String.self, forKey: .accessToken),
                .tokenType: try container.decode(String.self, forKey: .tokenType),
                .expiresIn: try container.decode(TimeInterval.self, forKey: .expiresIn),
            ]
            
            if let idToken = try container.decodeIfPresent(String.self, forKey: .idToken) {
                payload[.idToken] = idToken
            }

            if let scope = try container.decodeIfPresent(String.self, forKey: .scope) {
                payload[.scope] = scope
            }
            
            if let refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken) {
                payload[.refreshToken] = refreshToken
            }
            
            if let deviceSecret = try container.decodeIfPresent(String.self, forKey: .deviceSecret) {
                payload[.deviceSecret] = deviceSecret
            }

            json = .init(try JSON(payload.reduce(into: [String: Any]()) { result, item in
                result[item.key.rawValue] = item.value
            }))
        }

        // Attempt to decode V2 token data
        else if let container = try? decoder.container(keyedBy: CodingKeysV2.self),
           container.allKeys.contains(.id)
        {
            context = try container.decode(Context.self, forKey: .context)

            if container.contains(.id) {
                id = try container.decode(String.self, forKey: .id)
            }
            
            if container.contains(.issuedAt) {
                issuedAt = try container.decode(Date.self, forKey: .issuedAt)
            }
            
            json = .init(try container.decode(String.self, forKey: .rawValue))
        }
        
        // Attempt to decode JSON data
        else {
            let container = try decoder.singleValueContainer()
            json = .init(try container.decode(JSON.self))
        }
        
        guard let context = context else {
            throw TokenError.contextMissing
        }

        try self.init(id: id,
                      issuedAt: issuedAt,
                      context: context,
                      json: json)
    }
    
    convenience init(id: String,
                     issuedAt: Date,
                     tokenType: String,
                     expiresIn: TimeInterval,
                     accessToken: String,
                     scope: String?,
                     refreshToken: String?,
                     idToken: JWT?,
                     deviceSecret: String?,
                     context: Context) throws
    {
        var payload: [TokenClaim: Any] = [
            .accessToken: accessToken,
            .tokenType: tokenType,
            .expiresIn: expiresIn,
        ]
        
        if let idToken = idToken {
            payload[.idToken] = idToken.rawValue
        }

        if let scope = scope {
            payload[.scope] = scope
        }
        
        if let refreshToken = refreshToken {
            payload[.refreshToken] = refreshToken
        }
        
        if let deviceSecret = deviceSecret {
            payload[.deviceSecret] = deviceSecret
        }
        
        let json = try JSON(payload.reduce(into: [String: Any]()) { result, item in
            result[item.key.rawValue] = item.value
        })

        try self.init(id: id,
                      issuedAt: issuedAt,
                      context: context,
                      json: .init(json))
    }
}
