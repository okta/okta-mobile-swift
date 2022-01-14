//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public enum TokenError: Error {
    case tokenTypeMissing(_: Token.RevokeType)
    case refreshTokenMissing
    case contextMissing
    case tokenNotFound(_: Token)
}

/// Token information representing a user's access to a resource server, including access token, refresh token, and other related information.
public class Token: Codable, Equatable, Hashable, Expires {
    // The date this token was issued at.
    public var issuedAt: Date
    
    /// The string type of the token (e.g. `Bearer`).
    public let tokenType: String
    
    /// The expiration duration for this token.
    public let expiresIn: TimeInterval
    
    /// Access token.
    public let accessToken: String
    
    /// The scopes requested when this token was generated.
    public let scope: String
    
    /// The refresh token, if requested.
    public let refreshToken: String?
    
    /// The ID token, if requested.
    public let idToken: String?
    
    /// Defines the context this token was issued from.
    public let context: Context
    
    /// The Device secret, if requested in scope.
    public let deviceSecret: String?
    
    /// Return the relevant token string for the given type.
    /// - Parameter kind: Type of token string to return
    /// - Returns: Token string, or `nil` if this token doesn't contain the requested type.
    public func token(of kind: Kind) -> String? {
        switch kind {
        case .accessToken:
            return accessToken
        case .refreshToken:
            return refreshToken
        case .idToken:
            return idToken
        case .deviceSecret:
            return deviceSecret
        }
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.context == rhs.context &&
        lhs.accessToken == rhs.accessToken &&
        lhs.scope == rhs.scope
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(context)
        hasher.combine(accessToken)
        hasher.combine(scope)
    }

    required init(issuedAt: Date,
                  tokenType: String,
                  expiresIn: TimeInterval,
                  accessToken: String,
                  scope: String,
                  refreshToken: String?,
                  idToken: String?,
                  deviceSecret: String?,
                  context: Context)
    {
        self.issuedAt = issuedAt
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.accessToken = accessToken
        self.scope = scope
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.deviceSecret = deviceSecret
        self.context = context
    }
    
    required public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let context: Context
        if container.contains(.context) {
            context = try container.decode(Context.self, forKey: .context)
        } else if let baseUrl = decoder.userInfo[.baseURL] as? URL {
            context = Context(baseURL: baseUrl,
                              refreshSettings: decoder.userInfo[.refreshSettings] as? [String:String])
        } else {
            throw TokenError.contextMissing
        }
        
        self.init(issuedAt: Date.nowCoordinated,
                  tokenType: try container.decode(String.self, forKey: .tokenType),
                  expiresIn: try container.decode(TimeInterval.self, forKey: .expiresIn),
                  accessToken: try container.decode(String.self, forKey: .accessToken),
                  scope: try container.decode(String.self, forKey: .scope),
                  refreshToken: try container.decodeIfPresent(String.self, forKey: .refreshToken),
                  idToken: try container.decodeIfPresent(String.self, forKey: .idToken),
                  deviceSecret: try container.decodeIfPresent(String.self, forKey: .deviceSecret),
                  context: context)
    }
}

extension Token {
    /// Summarizes the context in which a token is valid.
    ///
    /// This includes information such as the ``baseURL`` where operations related to this token should be performed.
    public struct Context: Codable, Equatable, Hashable {
        /// The base URL from which this token was issued.
        public let baseURL: URL
        
        /// Settings required to be supplied to the authorization server when refreshing this token.
        let refreshSettings: [String:String]?
    }
}

extension Token {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case issuedAt
        case tokenType
        case expiresIn
        case accessToken
        case scope
        case refreshToken
        case idToken
        case deviceSecret
        case context
    }
}

extension CodingUserInfoKey {
    static let baseURL = CodingUserInfoKey(rawValue: "baseURL")!
    static let refreshSettings = CodingUserInfoKey(rawValue: "refreshSettings")!
}

public extension Token {
    /// The possible token types that can be revoked.
    enum RevokeType {
        case accessToken
        case refreshToken
        case deviceSecret
    }
    
    enum Kind: String {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case idToken      = "id_token"
        case deviceSecret = "device_secret"
    }
}
