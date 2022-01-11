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
    case baseURLMissing
    case tokenNotFound(_: Token)
}

public struct TokenConfiguration: Codable, Equatable, Hashable {
    let baseURL: URL
    let refreshSettings: [String:String]?
}

public protocol Expires {
    var expiresIn: TimeInterval { get }
    var expiresAt: Date { get }
    var issuedAt: Date { get }
    var isExpired: Bool { get }
    var isValid: Bool { get }
}

extension Expires {
    public var expiresAt: Date {
        return issuedAt.coordinated.addingTimeInterval(expiresIn)
    }
    
    public var isExpired: Bool {
        return Date.nowCoordinated > expiresAt
    }
    
    public var isValid: Bool { !isExpired }
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
    
    /// The base URL for operations related to this token.
    public let configuration: TokenConfiguration
    
    public func token(of kind: Kind) -> String? {
        switch kind {
        case .accessToken:
            return accessToken
        case .refreshToken:
            return refreshToken
        case .idToken:
            return idToken
        case .deviceSecret:
            return nil
        }
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.configuration == rhs.configuration &&
        lhs.accessToken == rhs.accessToken &&
        lhs.scope == rhs.scope
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuration)
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
                  configuration: TokenConfiguration)
    {
        self.issuedAt = issuedAt
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.accessToken = accessToken
        self.scope = scope
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.configuration = configuration
    }
    
    required public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let baseUrl = decoder.userInfo[.baseURL] as? URL else {
            throw TokenError.baseURLMissing
        }
        
        let refreshSettings = decoder.userInfo[.refreshSettings] as? [String:String]
        
        self.init(issuedAt: Date.nowCoordinated,
                  tokenType: try container.decode(String.self, forKey: .tokenType),
                  expiresIn: try container.decode(TimeInterval.self, forKey: .expiresIn),
                  accessToken: try container.decode(String.self, forKey: .accessToken),
                  scope: try container.decode(String.self, forKey: .scope),
                  refreshToken: try container.decodeIfPresent(String.self, forKey: .refreshToken),
                  idToken: try container.decodeIfPresent(String.self, forKey: .idToken),
                  configuration: TokenConfiguration(baseURL: baseUrl,
                                                    refreshSettings: refreshSettings))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(issuedAt, forKey: .issuedAt)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(scope, forKey: .scope)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encodeIfPresent(idToken, forKey: .idToken)
        try container.encodeIfPresent(configuration, forKey: .configuration)
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
        case configuration
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
    
//    /// Revokes the token.
//    /// - Parameters:
//    ///   - type: The type to revoke (e.g. access token, or refresh token).
//    ///   - completion: Completion handler for when the token is revoked.
//    func revoke(type: Token.RevokeType = .accessToken, completion: @escaping(Result<Void,TokenError>) -> Void) {
//
//    }
//
//    /// Refreshes the token.
//    ///
//    /// If no ailable, or  != nilthe tokens have been revoked, an error will be returned.
//    ///
//    /// > *Note:* Depending on organization or policy settings, the values contained within the token may or may not differ once the token is refreshed. Therefore, it may be necessary to save the newly-refeshed object for use in future requests.
//    /// - Parameters:
//    ///   - completion: Completion handler for when the token is revoked.
//    func refresh(completion: ((Result<Token,TokenError>) -> Void)?) {
//        guard refreshToken != nil else {
//            completion?(.failure(.refreshTokenMissing))
//            return
//        }
//
////        let request = RefreshRequest(token: refreshToken, configuration: <#T##TokenConfiguration#>)
//
////        let api = IDXClient.Version.latest.clientImplementation(with: configuration)
////        api.refresh(token: self) { result in
////            completion(result)
////        }
//    }
}
/*
#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension Token {
    /// Refreshes the token.
    ///
    /// If no refresh token is available, or the tokens have been revoked, an error will be returned.
    ///
    /// > *Note:* Depending on organization or policy settings, the values contained within the token may or may not differ once the token is refreshed. Therefore, it may be necessary to save the newly-refeshed object for use in future requests.
    @discardableResult
    public func refresh() async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            refresh() { result in
                continuation.resume(with: result)
            }
        }
    }

    /// Revokes the token.
    /// - Parameters:
    ///   - type: The type to revoke (e.g. access token, or refresh token).
    public func revoke(type: Token.RevokeType = .accessAndRefreshToken) async throws {
        try await withCheckedThrowingContinuation { continuation in
            revoke(type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif
*/
