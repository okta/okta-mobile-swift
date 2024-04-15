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

/// Token information representing a user's access to a resource server, including access token, refresh token, and other related information.
public final class Token: Codable, Equatable, Hashable, Expires {
    /// The object used to ensure ID tokens are valid.
    public static var idTokenValidator: IDTokenValidator = DefaultIDTokenValidator()
    
    /// The object used to ensure access tokens can be validated against its associated ID token.
    public static var accessTokenValidator: TokenHashValidator = DefaultTokenHashValidator(hashKey: .accessToken)
    
    /// The object used to ensure device secrets are validated against its associated ID token.
    public static var deviceSecretValidator: TokenHashValidator = DefaultTokenHashValidator(hashKey: .deviceSecret)
    
    /// The unique identifier for this token.
    public internal(set) var id: String
    
    // The date this token was issued at.
    public let issuedAt: Date?
    
    /// The string type of the token (e.g. `Bearer`).
    public let tokenType: String
    
    /// The expiration duration for this token.
    public let expiresIn: TimeInterval
    
    /// Access token.
    public let accessToken: String
    
    /// The scopes requested when this token was generated.
    public let scope: String?
    
    /// The refresh token, if requested.
    public let refreshToken: String?
    
    /// The ID token, if requested.
    ///
    /// For more information on working with an ID token, see the <doc:WorkingWithClaims> documentation.
    public let idToken: JWT?
    
    /// Defines the context this token was issued from.
    public let context: Context
    
    /// The Device secret, if requested in scope.
    public let deviceSecret: String?
    
    /// Indicates whether or not the token is being refreshed.
    public var isRefreshing: Bool {
        refreshAction != nil
    }
    
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
    public func validate(using client: OAuth2Client, with context: IDTokenValidatorContext?) throws {
        guard let idToken = idToken else {
            return
        }
        
        guard let issuer = client.openIdConfiguration?.issuer else {
            throw TokenError.invalidConfiguration
        }

        try Token.idTokenValidator.validate(token: idToken,
                                            issuer: issuer,
                                            clientId: client.configuration.clientId,
                                            context: context)
        try Token.accessTokenValidator.validate(accessToken, idToken: idToken)
        
        if let deviceSecret = deviceSecret {
            try Token.deviceSecretValidator.validate(deviceSecret, idToken: idToken)
        }
    }
    
    /// Creates a new Token from a refresh token.
    /// - Parameters:
    ///   - refreshToken: Refresh token string.
    ///   - client: ``OAuth2Client`` instance that corresponds to the client configuration initially used to create the refresh token.
    ///   - completion: Completion block invoked when a result is returned.
    public static func from(refreshToken: String, using client: OAuth2Client, completion: @escaping (Result<Token, OAuth2Error>) -> Void) {
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = Token.RefreshRequest(openIdConfiguration: configuration,
                                                   resource: "", 
                                                   clientSecret: "",
                                                   clientConfiguration: client.configuration,
                                                   refreshToken: refreshToken,
                                                   id: Token.RefreshRequest.placeholderId,
                                                   configuration: [
                                                    "client_id": client.configuration.clientId,
                                                    "scope": client.configuration.scopes
                                                ])
                client.exchange(token: request) { result in
                    switch result {
                    case .success(let response):
                        NotificationCenter.default.post(name: .tokenRefreshed, object: response.result)
                        completion(.success(response.result))

                    case .failure(let error):
                        completion(.failure(.network(error: error)))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.context == rhs.context &&
        lhs.accessToken == rhs.accessToken &&
        lhs.refreshToken == rhs.refreshToken &&
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

    required init(id: String,
                  issuedAt: Date,
                  tokenType: String,
                  expiresIn: TimeInterval,
                  accessToken: String,
                  scope: String?,
                  refreshToken: String?,
                  idToken: JWT?,
                  deviceSecret: String?,
                  context: Context)
    {
        self.id = id
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
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var context: Context
        if container.contains(.context) {
            context = try container.decode(Context.self, forKey: .context)
        } else if let configuration = decoder.userInfo[.apiClientConfiguration] as? OAuth2Client.Configuration {
            context = Context(configuration: configuration,
                              clientSettings: decoder.userInfo[.clientSettings])
        } else {
            throw TokenError.contextMissing
        }
        context.clientSettings?[Token.Kind.refreshToken.rawValue] = try? container.decode(String.self, forKey: .refreshToken)
        
        let id: String
        if let userInfoId = decoder.userInfo[.tokenId] as? String {
            id = userInfoId
        } else if container.contains(.id) {
            id = try container.decode(String.self, forKey: .id)
        } else {
            id = UUID().uuidString
        }

        var idToken: JWT?
        if let idTokenString = try container.decodeIfPresent(String.self, forKey: .idToken) {
            idToken = try JWT(idTokenString)
        }
        
        self.init(id: id,
                  issuedAt: try container.decodeIfPresent(Date.self, forKey: .issuedAt) ?? Date.nowCoordinated,
                  tokenType: try container.decode(String.self, forKey: .tokenType),
                  expiresIn: try container.decode(TimeInterval.self, forKey: .expiresIn),
                  accessToken: try container.decode(String.self, forKey: .accessToken),
                  scope: try container.decodeIfPresent(String.self, forKey: .scope),
                  refreshToken: try container.decodeIfPresent(String.self, forKey: .refreshToken),
                  idToken: idToken,
                  deviceSecret: try container.decodeIfPresent(String.self, forKey: .deviceSecret),
                  context: context)
    }
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension Token {
    /// Creates a new Token from a refresh token.
    /// - Parameters:
    ///   - refreshToken: Refresh token string.
    ///   - client: ``OAuth2Client`` instance that corresponds to the client configuration initially used to create the refresh token.
    /// - Returns: Token created using the refresh token.
    public static func from(refreshToken: String, using client: OAuth2Client) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            from(refreshToken: refreshToken, using: client) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension Token {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
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
    // swiftlint:disable force_unwrapping
    public static let tokenId = CodingUserInfoKey(rawValue: "tokenId")!
    public static let apiClientConfiguration = CodingUserInfoKey(rawValue: "apiClientConfiguration")!
    public static let clientSettings = CodingUserInfoKey(rawValue: "clientSettings")!
    // swiftlint:enable force_unwrapping
}
