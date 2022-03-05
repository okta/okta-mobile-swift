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

public enum JWTError: Error {
    case invalidBase64Encoding
    case badTokenStructure
    case missingIssuer
}

/// Represents the contents of a JWT token, providing access to its payload contents.
public struct JWT: RawRepresentable, Codable, HasClaims, Expires {
    public typealias RawValue = String
    public let rawValue: String
    
    public var expirationTime: Date? { self[.expirationTime] }
    
    public var issuer: String? { self[.issuer] }
    public var audience: [String]? { self[.audience] }
    public var issuedAt: Date? { self[.issuedAt] }
    public var notBefore: Date? { self[.notBefore] }
    public var expiresIn: TimeInterval { self[.expiresIn] ?? 0 }
    public var scope: [String]? { self[.scope] ?? self["scp"] }

    /// The list of standard claims contained within this JWT token.
    public var claims: [Claim] {
        payload.keys.compactMap { Claim(rawValue: $0) }
    }
    
    /// The list of custom claims contained within this JWT token.
    public var customClaims: [String] {
        payload.keys.filter { Claim(rawValue: $0) == nil }
    }

    public func value<T>(_ type: T.Type, for key: String) -> T? {
        payload[key] as? T
    }

    public struct Header: Decodable {
        public let keyId: String
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
    
    public init?(rawValue: RawValue) {
        try? self.init(rawValue)
    }
    
    public func validate(using client: OAuth2Client) throws {
        try JWT.validator.validate(token: self,
                                   issuer: client.configuration.baseURL,
                                   clientId: client.configuration.clientId)
    }
    
    public func verify(using key: JWK) throws -> Bool {
        try JWT.validator.verify(token: self, using: key)
    }
    
    public static var validator: JWTValidator = DefaultJWTValidator()
    static func resetToDefault() {
        validator = DefaultJWTValidator()
    }

    public let header: Header
    private let payload: [String:Any]
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
        self.payload = try JSONSerialization.jsonObject(with: payloadData, options: []) as! [String:Any]
    }
    
    static func tokenComponents(from token: String) -> [String] {
        token
            .components(separatedBy: ".")
            .map { $0.base64URLDecoded }
    }
}
