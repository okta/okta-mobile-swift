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

struct DefaultIDTokenValidator: IDTokenValidator {
    var issuedAtGraceInterval: TimeInterval = 300
    
    ///  This represents the validation checks using to  validate the claim
    enum Intent {
        case validateIssuer(token: JWT, issuer: URL)
        case validateAudience(token: JWT, clientId: String)
        case validateScheme(token: JWT)
        case validateAlgorithm(token: JWT)
        case validateNonce(token: JWT, context: IDTokenValidatorContext?)
        case validateIssuedAtTime(token: JWT)
        case validateExpirationTime(token: JWT)
        case validateAuthTime(token: JWT, context: IDTokenValidatorContext?)
        case validateMaxAge(token: JWT, context: IDTokenValidatorContext?)
        case validateSubject(token: JWT)
    }

    func validate(token: JWT, issuer: URL, clientId: String, context: IDTokenValidatorContext?) throws {
        let validationIntent: [Intent] = [
            .validateIssuer(token: token, issuer: issuer),
            .validateAudience(token: token, clientId: clientId),
            .validateScheme(token: token),
            .validateAlgorithm(token: token),
            .validateExpirationTime(token: token),
            .validateIssuedAtTime(token: token),
            .validateNonce(token: token, context: context),
            .validateAuthTime(token: token, context: context),
            .validateMaxAge(token: token, context: context),
            .validateSubject(token: token)
        ]
        return try self.validate(using: validationIntent)
    }
}

extension DefaultIDTokenValidator {
    /// Validates the claims in the given token, using the supplied intent
    /// - Parameter intent: The validation check requirement
    func validate(using intent: [Intent]) throws {
         try intent.forEach({ validationIntent in
            switch validationIntent {
            case .validateAudience(token: let token, clientId: let clientID):
                try self.validateAudience(using: token, clientId: clientID)
            case .validateIssuer(token: let token, issuer: let issuer):
                try self.validateIssuer(using: token, issuer: issuer)
            case .validateScheme(token: let token):
                try self.validateScheme(using: token)
            case .validateAlgorithm(token: let token):
                try self.validateAlgorithm(using: token)
            case .validateNonce(token: let token, context: let context):
                try self.validateNonce(using: token, context: context)
            case .validateIssuedAtTime(token: let token):
                try self.validateIssuedAtTime(using: token)
            case .validateExpirationTime(token: let token):
                try self.validateExpirationTime(using: token)
            case .validateAuthTime(token: let token, context: let context):
                try self.validateAuthTime(using: token, context: context)
            case .validateMaxAge(token: let token, context: let context):
                try self.validateMaxAge(using: token, context: context)
            case .validateSubject(token: let token):
                try self.validateSubject(using: token)
            }
        })
    }
    
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
    
    /// Validate rhe signing algorithm used to sign this JWT token.
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
