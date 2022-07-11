//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if canImport(CommonCrypto)
import CommonCrypto
#endif

/// This represents the possible option using in validating a claim
public struct ValidationOption: OptionSet  {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    ///  This represents the default validation checks in-order using to validate a claim
    public static let all: ValidationOption = [
        .validateIssuer,
        .validateAudience,
        .validateScheme,
        .validateAlgorithm,
        .validateExpirationTime,
        .validateIssuedAtTime,
        .validateNonce,
        .validateAuthTime,
        .validateMaxAge,
        .validateSubject
    ]
    
    /// Validate the Issuer claim of the token
    static let validateIssuer = ValidationOption(rawValue: 1 << 0)
    /// Validate the Audience claim
    static let validateAudience = ValidationOption(rawValue: 1 << 1)
    /// Validate the Issuer scheme  of the URL.
    static let validateScheme = ValidationOption(rawValue: 1 << 2)
    /// Validate the signing algorithm used to sign this JWT token.
    static let validateAlgorithm = ValidationOption(rawValue: 1 << 3)
    /// Validate the Expiration Time. exp claim
    static let validateExpirationTime = ValidationOption(rawValue: 1 << 4)
    /// Validate the date this token was issued. iat claim
    static let validateIssuedAtTime = ValidationOption(rawValue: 1 << 5)
    /// Validate the nonce claim
    static let validateNonce = ValidationOption(rawValue: 1 << 6)
    /// Validate the date at which authentication occurred.
    static let validateAuthTime = ValidationOption(rawValue: 1 << 7)
    /// Validate the maximum age the token should support when authenticating.
    static let validateMaxAge = ValidationOption(rawValue: 1 << 8)
    /// Validate the subject of the resource, if available.
    static let validateSubject = ValidationOption(rawValue: 1 << 9)
}

struct DefaultIDTokenValidator: IDTokenValidator {
    var issuedAtGraceInterval: TimeInterval = 300
        
    func validate(token: JWT, issuer: URL, clientId: String, context: IDTokenValidatorContext?) throws {
        let validationOptions = context?.validationOptions ?? .all
        
        if validationOptions.contains(.validateIssuer) {
            try self.validateIssuer(using: token, issuer: issuer)
        }

        if validationOptions.contains(.validateAudience) {
            try self.validateAudience(using: token, clientId: clientId)
        }

        if validationOptions.contains(.validateScheme) {
            try self.validateScheme(using: token)
        }

        if validationOptions.contains(.validateAlgorithm) {
            try self.validateAlgorithm(using: token)
        }

        if validationOptions.contains(.validateExpirationTime) {
            try self.validateExpirationTime(using: token)
        }

        if validationOptions.contains(.validateIssuedAtTime) {
            try self.validateIssuedAtTime(using: token)
        }

        if validationOptions.contains(.validateNonce) {
            try self.validateNonce(using: token, context: context)
        }

        if validationOptions.contains(.validateAuthTime) {
            try self.validateAuthTime(using: token, context: context)
        }

        if validationOptions.contains(.validateMaxAge) {
            try self.validateMaxAge(using: token, context: context)
        }

        if validationOptions.contains(.validateSubject) {
            try self.validateSubject(using: token)
        }
    }
}

extension DefaultIDTokenValidator {
    /// Validate the Issuer claim of the token
    /// - Parameters:
    ///   - token: JWT token, providing access to its payload contents.
    ///   - issuer: The supplied issuer
    private func validateIssuer(using token: JWT, issuer: URL) throws {
        guard let tokenIssuerString = token.issuer,
              let tokenIssuer = URL(string: tokenIssuerString),
              tokenIssuer.absoluteString == issuer.absoluteString
        else {
            throw JWTError.invalidIssuer
        }
        
        guard tokenIssuer.absoluteString == issuer.absoluteString
        else {
            throw JWTError.invalidIssuer
        }
    }
    
    /// Validate the Audience claim
    /// - Parameters:
    ///   - token: JWT token, providing access to its payload contents.
    ///   - clientId: The unique client ID
    private func validateAudience(using token: JWT, clientId: String) throws {
        guard token[.audience] == clientId else {
            throw JWTError.invalidAudience
        }
    }
    
    /// Validate the Issuer scheme  of the URL.
    /// - Parameter token: JWT token, providing access to its payload contents.
    private func validateScheme(using token: JWT) throws {
        guard let tokenIssuerString = token.issuer,
            let tokenIssuer = URL(string: tokenIssuerString)
        else {
            throw JWTError.invalidIssuer
        }

        guard tokenIssuer.scheme == "https" else {
            throw JWTError.issuerRequiresHTTPS
        }
    }
    
    /// Validate the signing algorithm used to sign this JWT token.
    /// - Parameter token: JWT token, providing access to its payload contents.
    private func validateAlgorithm(using token: JWT) throws {
        guard token.header.algorithm == .rs256 else {
            throw JWTError.unsupportedAlgorithm(token.header.algorithm)
        }
    }
    
    /// Validate the nonce claim
    /// - Parameters:
    ///   - token: JWT token, providing access to its payload contents.
    private func validateNonce(using token: JWT, context: IDTokenValidatorContext?) throws {
        guard token["nonce"] == context?.nonce else {
            throw JWTError.nonceMismatch
        }
    }
    
    /// Validate the date this token was issued. iat claim
    /// - Parameter token: JWT token, providing access to its payload contents.
    private func validateIssuedAtTime(using token: JWT) throws {
        guard let issuedAt = token.issuedAt,
              abs(issuedAt.timeIntervalSince(Date.nowCoordinated)) <= issuedAtGraceInterval
        else {
            throw JWTError.issuedAtTimeExceedsGraceInterval
        }
    }
    
    /// Validate the Expiration Time. exp claim
    /// - Parameter token: JWT token, providing access to its payload contents.
    private func validateExpirationTime(using token: JWT) throws {
        guard let expirationTime = token.expirationTime,
              expirationTime > Date.nowCoordinated else {
            throw JWTError.expired
        }
    }
    
    /// Validate the date at which authentication occurred.
    /// - Parameters:
    ///   - token: JWT token, providing access to its payload contents.
    private func validateAuthTime(using token: JWT, context: IDTokenValidatorContext?) throws {
        if (context?.maxAge) != nil {
            guard token.authTime != nil else {
                throw JWTError.invalidAuthenticationTime
            }
        }
    }
    
    /// Validate the maximum age the token should support when authenticating.
    /// - Parameters:
    ///   - token: JWT token, providing access to its payload contents.
    private func validateMaxAge(using token: JWT, context: IDTokenValidatorContext?) throws {
        if let maxAge = context?.maxAge {
             guard let authTime = token.authTime else {
                 throw JWTError.invalidAuthenticationTime
             }

            guard let issuedAt = token.issuedAt,
                  abs(issuedAt.timeIntervalSince(Date.nowCoordinated)) <= issuedAtGraceInterval
            else {
                throw JWTError.issuedAtTimeExceedsGraceInterval
            }
            let elapsedTime = issuedAt.timeIntervalSince(authTime)
            guard elapsedTime > 0 && elapsedTime <= maxAge else {
                 throw JWTError.exceedsMaxAge
             }
         }
    }
    
    /// Validate the subject of the resource, if available.
    /// - Parameter token: JWT token, providing access to its payload contents.
    private func validateSubject(using token: JWT) throws {
        guard let subject = token.subject,
              !subject.isEmpty
        else {
            throw JWTError.invalidSubject
        }
    }
}
