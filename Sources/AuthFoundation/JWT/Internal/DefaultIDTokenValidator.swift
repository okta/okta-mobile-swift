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
    
    func validate(token: JWT, issuer: URL, clientId: String) throws {
        guard let tokenIssuerString = token.issuer,
              let tokenIssuer = URL(string: tokenIssuerString)
        else {
            throw JWTError.invalidIssuer
        }

        guard tokenIssuer.absoluteString == issuer.absoluteString
        else {
            throw JWTError.invalidIssuer
        }

        guard token[.audience] == clientId else {
            throw JWTError.invalidAudience
        }

        guard tokenIssuer.scheme == "https" else {
            throw JWTError.issuerRequiresHTTPS
        }
        
        guard token.header.algorithm == .rs256 else {
            throw JWTError.invalidSigningAlgorithm
        }
        
        guard let expirationTime = token.expirationTime,
              expirationTime > Date.nowCoordinated else {
            throw JWTError.expired
        }
        
        guard let issuedAt = token.issuedAt,
              abs(issuedAt.timeIntervalSince(Date.nowCoordinated)) <= issuedAtGraceInterval
        else {
            throw JWTError.issuedAtTimeExceedsGraceInterval
        }
    }
}
