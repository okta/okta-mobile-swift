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
import OktaUtilities
import OktaConcurrency
import JWT

/// Token information representing a user's access to a resource server, including access token, refresh token, and other related information.
public final class Token: Codable, Equatable, Hashable, Sendable, JSONClaimContainer, Expires {
    public typealias ClaimType = TokenClaim
    
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
    public var scope: String? { self[.scope] }
    
    /// The refresh token, if requested.
    public var refreshToken: String? { self[.refreshToken] }
    
    /// The ID token, if requested.
    ///
    /// For more information on working with an ID token, see the <doc:WorkingWithClaims> documentation.
    public let idToken: JWT?
    
    /// Defines the context this token was issued from.
    public let context: Context
    
    /// The Device secret, if requested in scope.
    public var deviceSecret: String? { self[.deviceSecret] }
    
    /// The type of token issued to the client when using Token Exchange Flow.
    public var issuedTokenType: String? { self[.issuedTokenType] }
    
    /// The claim payload container for this token
    public var payload: [String: any Sendable] { jsonPayload.jsonValue.anyValue as? [String: any Sendable] ?? [:] }
    
    /// Indicates whether or not the token is being refreshed.
    public var isRefreshing: Bool {
        refreshAction.isActive
    }
    
    let jsonPayload: AnyJSON
    internal let refreshAction = CoalescedResult<Result<Token, OAuth2Error>>()

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
    public func validate(using client: OAuth2Client, with context: (any IDTokenValidatorContext)?) throws {
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
    public static func from(refreshToken: String, using client: OAuth2Client, completion: @Sendable @escaping (Result<Token, OAuth2Error>) -> Void) {
        client.openIdConfiguration { result in
            switch result {
            case .success(let configuration):
                let request = Token.RefreshRequest(openIdConfiguration: configuration,
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
         json: AnyJSON) throws
    {
        self.id = id
        self.issuedAt = issuedAt
        self.context = context
        self.jsonPayload = json
        
        let payload = json.jsonValue.anyValue as? [String: any Sendable] ?? [:]
        if let value = payload[TokenClaim.idToken.rawValue] as? String {
            idToken = try JWT(value)
        } else {
            idToken = nil
        }
        
        // Ensure an access token is provided.
        if let value: String = TokenClaim.optionalValue(.accessToken, in: payload) {
            accessToken = value
        }
        
        // When the custom MFA attestation ACR value is used, allow for
        // an empty / unspecified access token.
        else if let acrValues = idToken?.authenticationClassReference,
                acrValues.contains("urn:okta:app:mfa:attestation")
        {
            accessToken = ""
        }
        
        // Throw an error when no access token is available.
        else {
            throw ClaimError.missingRequiredValue(key: TokenClaim.accessToken.rawValue)
        }

        tokenType = try TokenClaim.value(.tokenType, in: payload)
        expiresIn = try TokenClaim.value(.expiresIn, in: payload)
    }
    
    func with(tags: [String: String]?) throws -> Token {
        guard let tags = tags else {
            return self
        }
        
        var result = self
        
        var newContext = context
        newContext.tags = tags
        
        result = try Token(id: id,
                           issuedAt: issuedAt ?? Date(),
                           context: newContext,
                           json: jsonPayload)
        return result
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeysV2.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(issuedAt, forKey: .issuedAt)
        try container.encode(context, forKey: .context)
        try container.encode(jsonPayload.stringValue, forKey: .rawValue)
    }
}

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
    public static let clientSettings = CodingUserInfoKey(rawValue: "clientSettings")!
    public static let request = CodingUserInfoKey(rawValue: "request")!
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
