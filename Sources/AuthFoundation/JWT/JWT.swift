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

/// Represents the contents of a JWT token, providing access to its payload contents.
public struct JWT: RawRepresentable, Codable, HasClaims, Expires {
    public typealias ClaimType = JWTClaim
    public typealias RawValue = String
    
    /// The raw string representation of this JWT token.
    public let rawValue: String
    
    /// The date this token will expire.
    public var expirationTime: Date? { self[.expirationTime] }
    
    /// The issuer claim for this token.
    public var issuer: String? { self[.issuer] }
    
    /// The intended audience for this token.
    public var audience: [String]? { self[.audience] }
    
    /// The date this token was issued.
    public var issuedAt: Date? { self[.issuedAt] }
    
    public var notBefore: Date? { self[.notBefore] }
    
    /// The time interval in which the token will expire.
    public var expiresIn: TimeInterval { self[.expiresIn] ?? 0 }
    
    /// The array of scopes this token is valid for.
    public var scope: [String]? { self[.scope] ?? self["scp"] }

    // VIP Roles for application access
    public var roles: [String]? { self[.roles] }
    
    /// The authentication context class reference.
    ///
    /// The ``JWTClaim/authContextClassReference`` claim (or `acr` in string form) defines a special authentication context reference which indicates additional policy choices requested when authenticating a user.
    public var authenticationContext: String? { self[.authContextClassReference] }
    
    /// JWT header information describing the contents of the token.
    public struct Header: Decodable {
        /// The ID of the key used to sign this JWT token.
        public let keyId: String

        /// The signing algorithm used to sign this JWT token.
        public let algorithm: JWK.Algorithm
        
        enum CodingKeys: String, CodingKey {
            case keyId = "kid"
            case algorithm = "alg"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            keyId = try container.decode(String.self, forKey: .keyId)
            algorithm = try container.decode(JWK.Algorithm.self, forKey: .algorithm)
        }
    }
    
    /// Initializer to create a JWT instance from a raw string value.
    /// - Parameter rawValue: Raw string value of the JWT.
    public init?(rawValue: RawValue) {
        try? self.init(rawValue)
    }
    
    /// Verifies the JWT token using the given ``JWK`` key.
    /// - Parameter key: JWK key to use to verify this token.
    /// - Returns: Returns whether or not signing passes for this token/key combination.
    /// - Throws: ``JWTError``
    public func validate(using keySet: JWKS) throws -> Bool {
        return try JWK.validator.validate(token: self, using: keySet)
    }
    
    /// The header portion of the JWT token.
    public let header: Header
    
    /// Designated initializer, accepting the token string.
    /// - Parameter token: Token string.
    public init(_ token: String) throws {
        rawValue = token
        
        let components = JWT.tokenComponents(from: rawValue)
        guard components.count == 3 else {
            throw JWTError.badTokenStructure
        }
        
        guard let headerData = Data(base64Encoded: components[0]),
              let payloadData = Data(base64Encoded: components[1])
        else { throw JWTError.invalidBase64Encoding }
        
        self.header = try JSONDecoder().decode(JWT.Header.self, from: headerData)
        guard let payload = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            throw JWTError.badTokenStructure
        }
        
        self.payload = payload
    }
    
    /// Raw paylaod of claims, as a dictionary representation.
    public let payload: [String: Any]

    static func tokenComponents(from token: String) -> [String] {
        token
            .components(separatedBy: ".")
            .map(\.base64URLDecoded)
    }
}
