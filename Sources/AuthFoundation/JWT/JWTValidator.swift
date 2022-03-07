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

#if os(Linux)
public typealias OSStatus = Int32
#endif

public enum JWTValidatorError: Error {
    case invalidIssuer
    case invalidAudience
    case issuerRequiresHTTPS
    case invalidSigningAlgorithm
    case expired
    case issuedAtTimeExceedsGraceInterval
    case keySignatureNotFound
    case cannotCreateKey(code: OSStatus, description: String?)
    case invalidKey
    case unsupportedAlgorithm(_ algorithm: JWK.Algorithm?)
    case signatureVerificationUnavailable
    case generic(error: Error)
}

/// Protocol used to implement ``JWT`` token validation and verification steps.
///
/// Instances of this protocol may be assigned to ``JWT/validator`` to override the mechanisms used to validate tokens.
///
/// > Note: A default implementation will be automatically used if this value is not changed.
public protocol JWTValidator {
    /// The time interval grace period that will be permitted when verifying the ``Token/issuedAt`` value.
    ///
    /// *Default:* 5 minutes.
    var issuedAtGraceInterval: TimeInterval { get set }
    
    /// Validates the claims in the given ``JWT`` token, using the supplied issuer and client ID values.
    func validate(token: JWT, issuer: URL, clientId: String) throws
    
    /// Verifies the ``JWT`` signature using the supplied ``JWK`` key.
    /// - Returns: Returns whether or not signing passes for this token/key combination.
    func verify(token: JWT, using key: JWK) throws -> Bool
}
