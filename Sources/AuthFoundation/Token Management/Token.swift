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

#if !COCOAPODS
import CommonSupport
@_exported import JSON
#endif

/// Token information representing a user's access to a resource server, including access token, refresh token, and other related information.
public struct Token: Sendable, Codable, Equatable, Hashable, HasClaims, Expires {
    public typealias ClaimType = TokenClaim

    /// The object used to ensure ID tokens are valid.
    public static var idTokenValidator: any IDTokenValidator {
        get {
            lock.withLock { _idTokenValidator }
        }
        set {
            lock.withLock { _idTokenValidator = newValue }
        }
    }

    /// The object used to ensure access tokens can be validated against its associated ID token.
    public static var accessTokenValidator: any TokenHashValidator  {
        get {
            lock.withLock { _accessTokenValidator }
        }
        set {
            lock.withLock { _accessTokenValidator = newValue }
        }
    }

    /// The object used to ensure device secrets are validated against its associated ID token.
    public static var deviceSecretValidator: any TokenHashValidator  {
        get {
            lock.withLock { _deviceSecretValidator }
        }
        set {
            lock.withLock { _deviceSecretValidator = newValue }
        }
    }

    /// Coordinates important operations during token exchange.
    ///
    /// > Note: This property and interface is currently marked as internal, but may be exposed publicly in the future.
    static var exchangeCoordinator: any TokenExchangeCoordinator  {
        get {
            lock.withLock { _exchangeCoordinator }
        }
        set {
            lock.withLock { _exchangeCoordinator = newValue }
        }
    }

    /// The unique identifier for this token.
    public let id: String

    /// The date this token was issued at.
    public let issuedAt: Date?
    
    /// The string type of the token (e.g. `Bearer`).
    public let tokenType: String
    
    /// The expiration duration for this token.
    public let expiresIn: TimeInterval
    
    /// Access token.
    public let accessToken: String
    
    /// The scopes requested when this token was generated.
    public var scope: [String]? { self[.scope] }
    
    /// The refresh token, if requested.
    public var refreshToken: String? { self[.refreshToken] }
    
    /// The ID token, if requested.
    ///
    /// For more information on working with an ID token, see ``HasClaims`` for more.
    public let idToken: JWT?
    
    /// Defines the context this token was issued from.
    public let context: Context
    
    /// The Device secret, if requested in scope.
    public var deviceSecret: String? { self[.deviceSecret] }
    
    /// The type of token issued to the client when using Token Exchange Flow.
    public var issuedTokenType: String? { self[.issuedTokenType] }
    
    /// The claim payload container for this token
    @_documentation(visibility: internal)
    public var claimContent: [String: any Sendable] { json.claimContent }

    /// Indicates whether or not the token is being refreshed.
    public var isRefreshing: Bool {
        refreshAction.isActive
    }
    
    public let json: JSON
    internal let refreshAction: CoalescedResult<Token>

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
    /// - Parameters:
    ///   - client: Client to validate the token's claims against.
    ///   - context: Optional ``IDTokenValidatorContext`` to use when validating the token.
    public func validate(using client: OAuth2Client, with context: any IDTokenValidatorContext) async throws {
        guard let idToken = idToken else {
            return
        }
        
        let issuer = try await client.openIdConfiguration().issuer
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
    ///   - scope: Optional array of scopes to request.
    ///   - client: ``OAuth2Client`` instance that corresponds to the client configuration initially used to create the refresh token.
    public static func from(refreshToken: String,
                            scope: [String]? = nil,
                            using client: OAuth2Client) async throws -> Token
    {
        let request = Token.RefreshRequest(openIdConfiguration: try await client.openIdConfiguration(),
                                           clientConfiguration: client.configuration,
                                           refreshToken: refreshToken,
                                           scope: scope?.joined(separator: " "),
                                           id: Token.RefreshRequest.placeholderId)
        let response = try await client.exchange(token: request)
        TaskData.notificationCenter.post(name: .tokenRefreshed, object: response.result)
        return response.result
    }
    
    @_documentation(visibility: private)
    public static let jsonDecoder = JSONDecoder()
    
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

    init(id: String,
         issuedAt: Date,
         context: Context,
         json: JSON) throws
    {
        self.id = id
        self.issuedAt = issuedAt
        self.context = context
        self.json = json
        self.refreshAction = .init(taskName: "Refresh Token \(id)")
        
        if let value = json[TokenClaim.idToken.rawValue]?.string {
            idToken = try JWT(value)
        } else {
            idToken = nil
        }
        
        // Ensure an access token is provided.
        if let value: String = TokenClaim.optionalValue(.accessToken, in: json.claimContent) {
            accessToken = value
        }
        
        // When the custom MFA attestation ACR value is used, allow for
        // an empty / unspecified access token.
        else if let acrValues = context.clientSettings?["acr_values"]?.whitespaceSeparated,
                acrValues.contains("urn:okta:app:mfa:attestation")
        {
            accessToken = ""
        }
        
        // Throw an error when no access token is available.
        else {
            throw ClaimError.missingRequiredValue(key: TokenClaim.accessToken.rawValue)
        }

        tokenType = try TokenClaim.value(.tokenType, in: json.claimContent)
        expiresIn = try TokenClaim.value(.expiresIn, in: json.claimContent)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeysV2.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(issuedAt, forKey: .issuedAt)
        try container.encode(context, forKey: .context)
        try container.encode(json, forKey: .rawValue)
    }

    // MARK: Private properties / methods
    private static let lock = Lock()
    nonisolated(unsafe) private static var _idTokenValidator: any IDTokenValidator = DefaultIDTokenValidator()
    nonisolated(unsafe) private static var _accessTokenValidator: any TokenHashValidator = DefaultTokenHashValidator(hashKey: .accessToken)
    nonisolated(unsafe) private static var _deviceSecretValidator: any TokenHashValidator = DefaultTokenHashValidator(hashKey: .deviceSecret)
    nonisolated(unsafe) private static var _exchangeCoordinator: any TokenExchangeCoordinator = DefaultTokenExchangeCoordinator()
}

extension Token {
    /// Creates a new Token from a refresh token.
    /// - Parameters:
    ///   - refreshToken: Refresh token string.
    ///   - scope: Optional array of scopes to request.
    ///   - client: ``OAuth2Client`` instance that corresponds to the client configuration initially used to create the refresh token.
    ///   - completion: Completion block invoked when a result is returned.
    public static func from(refreshToken: String,
                            scope: [String]? = nil,
                            using client: OAuth2Client,
                            completion: @Sendable @escaping (Result<Token, OAuth2Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await from(refreshToken: refreshToken,
                                                   scope: scope,
                                                   using: client)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension Token {
    enum CodingKeysV1: String, CodingKey, CaseIterable {
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

    enum CodingKeysV2: String, CodingKey, CaseIterable {
        case id
        case issuedAt
        case context
        case rawValue
    }
}

@_documentation(visibility: private)
extension CodingUserInfoKey {
    // swiftlint:disable force_unwrapping
    public static let tokenId = CodingUserInfoKey(rawValue: "tokenId")!
    public static let apiClientConfiguration = CodingUserInfoKey(rawValue: "apiClientConfiguration")!
    public static let tokenContext = CodingUserInfoKey(rawValue: "tokenContext")!
    public static let clientSettings = CodingUserInfoKey(rawValue: "clientSettings")!
    // swiftlint:enable force_unwrapping
}

extension Token {
    public enum TokenClaim: String, IsClaim, CaseIterable {
        // Core OAuth 2.0 (RFC 6749)
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        
        // OpenID Connect (OIDC)
        case idToken = "id_token"
        
        // OAuth 2.0 Token Exchange (RFC 8693)
        case issuedTokenType = "issued_token_type"

        // OpenID Connect Native SSO for Mobile Apps 1.0
        case deviceSecret = "device_secret"
    }
}
