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
    case cannotReplaceToken
    case duplicateTokenAdded
}

/// Token information representing a user's access to a resource server, including access token, refresh token, and other related information.
public class Token: Codable, Equatable, Hashable, Identifiable, Expires {
    public static var idTokenValidator: IDTokenValidator = DefaultIDTokenValidator()
    
    // The date this token was issued at.
    public var issuedAt: Date?
    
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
    public let idToken: JWT?
    
    /// Defines the context this token was issued from.
    public let context: Context
    
    /// The Device secret, if requested in scope.
    public let deviceSecret: String?

    public var isRefreshing: Bool {
        refreshAction != nil
    }
    
    public typealias ID = String
    public lazy var id: String = {
        if let jwt = try? JWT(accessToken),
           let cid: String = jwt[.clientId],
           let uid: String = jwt[.userId]
        {
            return "\(cid).\(uid)"
        }
        
        if let idToken = idToken,
           let subject = idToken.subject
        {
            return subject
        }

        return UUID().uuidString
    }()

    internal var refreshAction: CoalescedResult<Result<Token, OAuth2Error>>?

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
            return idToken?.rawValue
        case .deviceSecret:
            return deviceSecret
        }
    }
    
    /// Validates the claims within this JWT token, to ensure it matches the given ``OAuth2Client``.
    /// - Parameter client: Client to validate the token's claims against.
    public func validate(using client: OAuth2Client) throws {
        guard let idToken = idToken else {
            return
        }

        try Token.idTokenValidator.validate(token: idToken,
                                            issuer: client.configuration.baseURL,
                                            clientId: client.configuration.clientId)
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.context == rhs.context &&
        lhs.accessToken == rhs.accessToken &&
        lhs.scope == rhs.scope &&
        lhs.idToken?.rawValue == rhs.idToken?.rawValue &&
        lhs.deviceSecret == rhs.deviceSecret
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(context)
        hasher.combine(accessToken)
        hasher.combine(scope)
        hasher.combine(idToken?.rawValue)
        hasher.combine(deviceSecret)
    }

    required init(issuedAt: Date,
                  tokenType: String,
                  expiresIn: TimeInterval,
                  accessToken: String,
                  scope: String,
                  refreshToken: String?,
                  idToken: JWT?,
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
        } else if let configuration = decoder.userInfo[.apiClientConfiguration] as? OAuth2Client.Configuration {
            context = Context(configuration: configuration,
                              clientSettings: decoder.userInfo[.clientSettings])
        } else {
            throw TokenError.contextMissing
        }
        
        var idToken: JWT? = nil
        if let idTokenString = try container.decodeIfPresent(String.self, forKey: .idToken) {
            idToken = try JWT(idTokenString)
        }
        
        self.init(issuedAt: Date.nowCoordinated,
                  tokenType: try container.decode(String.self, forKey: .tokenType),
                  expiresIn: try container.decode(TimeInterval.self, forKey: .expiresIn),
                  accessToken: try container.decode(String.self, forKey: .accessToken),
                  scope: try container.decode(String.self, forKey: .scope),
                  refreshToken: try container.decodeIfPresent(String.self, forKey: .refreshToken),
                  idToken: idToken,
                  deviceSecret: try container.decodeIfPresent(String.self, forKey: .deviceSecret),
                  context: context)
    }
}

extension Token {
    /// Summarizes the context in which a token is valid.
    ///
    /// This includes information such as the client configuration or settings required for token refresh.
    public struct Context: Codable, Equatable, Hashable {
        /// The base URL from which this token was issued.
        public let configuration: OAuth2Client.Configuration
        
        /// Settings required to be supplied to the authorization server when refreshing this token.
        let clientSettings: [String:String]?
        
        init(configuration: OAuth2Client.Configuration, clientSettings: Any?) {
            self.configuration = configuration
            
            if let settings = clientSettings as? [String:String]? {
                self.clientSettings = settings
            }
            
            else if let settings = clientSettings as? [CodingUserInfoKey: String] {
                self.clientSettings = settings.reduce(into: [String:String]()) { (partialResult, tuple: (key: CodingUserInfoKey, value: String)) in
                    partialResult[tuple.key.rawValue] = tuple.value
                }
            } else {
                self.clientSettings = nil
            }
        }
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
    public static let apiClientConfiguration = CodingUserInfoKey(rawValue: "apiClientConfiguration")!
    public static let clientSettings = CodingUserInfoKey(rawValue: "clientSettings")!
}

public extension Token {
    /// The possible token types that can be revoked.
    enum RevokeType {
        /// Indicates the access token should be revoked.
        case accessToken
        
        /// Indicates the refresh token should be revoked, if one is present. This will result in the access token being revoked as well.
        case refreshToken
        
        /// Indicates the device secret should be revoked.
        case deviceSecret
    }
    
    /// The kind of access token an operation should be used with.
    enum Kind: String {
        /// Indicates the access token.
        case accessToken = "access_token"
        
        /// Indicates the refresh token.
        case refreshToken = "refresh_token"
        
        /// Indicates the ID token.
        case idToken = "id_token"
        
        /// Indicates the device secret.
        case deviceSecret = "device_secret"
    }
}
