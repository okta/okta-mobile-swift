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
    var checks: [ValidationCheck] = ValidationCheck.allCases
    
    enum ValidationCheck: CaseIterable {
        case issuer, audience, scheme, algorithm, expirationTime, issuedAtTime, nonce, authTime, maxAge, subject
    }
    
    func validate(token: JWT, issuer: URL, clientId: String, context: IDTokenValidatorContext?) throws {
        guard let tokenIssuerString = token.issuer,
              let tokenIssuer = URL(string: tokenIssuerString),
              tokenIssuer.absoluteString == issuer.absoluteString
        else {
            throw JWTError.invalidIssuer
        }
        
        try checks.forEach({ check in
            switch check {
            case .issuer:
                guard tokenIssuer.absoluteString == issuer.absoluteString
                else {
                    throw JWTError.invalidIssuer
                }
            case .audience:
                guard token[.audience] == clientId else {
                    throw JWTError.invalidAudience
                }
            case .scheme:
                guard tokenIssuer.scheme == "https" else {
                    throw JWTError.issuerRequiresHTTPS
                }
            case .algorithm:
                guard token.header.algorithm == .rs256 else {
                    throw JWTError.unsupportedAlgorithm(token.header.algorithm)
                }
            case .expirationTime:
                guard let expirationTime = token.expirationTime,
                      expirationTime > Date.nowCoordinated else {
                    throw JWTError.expired
                }
            case .nonce:
                guard token["nonce"] == context?.nonce else {
                    throw JWTError.nonceMismatch
                }
            case .issuedAtTime, .authTime, .maxAge:
                guard let issuedAt = token.issuedAt,
                      abs(issuedAt.timeIntervalSince(Date.nowCoordinated)) <= issuedAtGraceInterval
                else {
                    throw JWTError.issuedAtTimeExceedsGraceInterval
                }
                
                if let maxAge = context?.maxAge {
                    guard let authTime = token.authTime else {
                        throw JWTError.invalidAuthenticationTime
                    }
                    
                    let elapsedTime = issuedAt.timeIntervalSince(authTime)
                    guard elapsedTime > 0 && elapsedTime <= maxAge else {
                        throw JWTError.exceedsMaxAge
                    }
                }
            case .subject:
                guard let subject = token.subject,
                      !subject.isEmpty
                else {
                    throw JWTError.invalidSubject
                }
            }
        })
    }
}
