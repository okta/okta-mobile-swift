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

public protocol JWTClaim {}

public enum JWTError: Error {
    case invalidBase64Encoding
    case badTokenStructure
}

public struct JWT: RawRepresentable, Codable {
    public typealias RawValue = String
    
    public let rawValue: String
        
    public var expirationTime: Date? { self[.expirationTime] }
    
    public var issuer: String? { self[.issuer] }
    public var subject: String? { self[.subject] }
    public var audience: [String]? { self[.audience] }
    public var issuedAt: Date? { self[.issuedAt] }
    public var notBefore: Date? { self[.notBefore] }
    public var expiresIn: TimeInterval { self[.expiresIn] ?? 0 }
    
    public var allClaims: [Claim] { payload.keys.compactMap { Claim(rawValue: $0) } }
    public var allClaimStrings: [String] { payload.keys.compactMap { $0 } }
    public var scope: [String]? { self[.scope] ?? self["scp"] }

    var expired: Bool {
        false
    }
    
    public subscript<T>(_ claim: Claim) -> T? {
        payload[claim.rawValue] as? T
    }
    
    public subscript<T>(_ claim: String) -> T? {
        payload[claim] as? T
    }
    
    public subscript(_ claim: Claim) -> Date? {
        guard let time: TimeInterval = self[claim] else { return nil }
        return Date(timeIntervalSince1970: time)
    }
    
    public subscript(_ claim: String) -> Date? {
        guard let time: TimeInterval = self[claim] else { return nil }
        return Date(timeIntervalSince1970: time)
    }
    
    public enum Algorithm: String, Codable {
        case hs256 = "HS256"
        case hs384 = "HS384"
        case hs512 = "HS512"
        case rs256 = "RS256"
        case rs384 = "RS384"
        case rs512 = "RS512"
        case es256 = "ES256"
        case es384 = "ES384"
        case es512 = "ES512"
    }
    
    public struct Header: Decodable {
        public let kid: String
        public let alg: Algorithm
    }
    
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }
    
    private let header: Header
    private let payload: [String:Any]
    private let signature: String?
    public init(_ token: String) throws {
        rawValue = token
        
        let components: [String] = token
            .components(separatedBy: ".")
            .map { $0.replacingOccurrences(of: "-", with: "+") }
            .map { $0.replacingOccurrences(of: "_", with: "/") }
            .map { component in
                var suffix = ""
                switch (component.count % 4) {
                case 1:
                    suffix = "==="
                case 2:
                    suffix = "=="
                case 3:
                    suffix = "="
                default: break
                }
                return "\(component)\(suffix)"
            }

        guard components.count == 3 else {
            throw JWTError.badTokenStructure
        }
        
        guard let headerData = Data(base64Encoded: components[0]),
              let payloadData = Data(base64Encoded: components[1])
        else { throw JWTError.invalidBase64Encoding }

        header = try JSONDecoder().decode(JWT.Header.self, from: headerData)
        payload = try JSONSerialization.jsonObject(with: payloadData, options: []) as! [String:Any]
        signature = components[2]
    }
}

extension String: JWTClaim {}
extension Bool: JWTClaim {}
extension Double: JWTClaim {}
extension Int: JWTClaim {}
extension Date: JWTClaim {}
extension Array: JWTClaim where Element == String {}
