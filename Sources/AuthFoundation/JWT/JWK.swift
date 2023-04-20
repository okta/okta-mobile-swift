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

/// Describes an individual key from an authorization server, which can be used to validate tokens or encrypt content.
///
/// > Warning: At this time, this class only supports RSA Public Keys.
public struct JWK: Codable, Equatable, Identifiable, Hashable {
    /// The type of this key.
    public let type: KeyType
    
    /// The key's ID.
    public let id: String?
    
    /// The intended usage for this key.
    public let usage: Usage

    /// The signing algorithm used with this key.
    public let algorithm: Algorithm?

    /// The RSA modulus value.
    public let rsaModulus: String?

    /// The RSA exponent value.
    public let rsaExponent: String?
        
    /// The validator instance used to perform verification steps on JWT tokens.
    ///
    /// A default implementation of ``JWKValidator`` is provided and will be used if this value is not changed.
    public static var validator: JWKValidator = DefaultJWKValidator()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(KeyType.self, forKey: .keyType)
        id = try container.decodeIfPresent(String.self, forKey: .keyId)
        usage = try container.decode(Usage.self, forKey: .usage)
        rsaModulus = try container.decodeIfPresent(String.self, forKey: .rsaModulus)
        rsaExponent = try container.decodeIfPresent(String.self, forKey: .rsaExponent)

        if let algorithm = try container.decodeIfPresent(JWK.Algorithm.self, forKey: .algorithm) {
            self.algorithm = algorithm
        } else if type == .rsa {
            self.algorithm = .rs256
        } else {
            self.algorithm = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .keyType)
        try container.encodeIfPresent(id, forKey: .keyId)
        try container.encodeIfPresent(usage, forKey: .usage)
        try container.encodeIfPresent(algorithm, forKey: .algorithm)
        try container.encodeIfPresent(rsaModulus, forKey: .rsaModulus)
        try container.encodeIfPresent(rsaExponent, forKey: .rsaExponent)
    }
    
    enum CodingKeys: String, CodingKey {
        case keyType = "kty"
        case keyId = "kid"
        case usage = "use"
        case algorithm = "alg"
        case rsaModulus = "n"
        case rsaExponent = "e"

        // Currently unused coding keys.
        case keyOperations = "key_ops"
        case certificateUrl = "x5u"
        case certificateChain = "x5c"
        case certificateThumbprint = "x5t"
        case certificateSHA256Thumbprint = "x5t#S256"
        case privateKey = "d"
        case eccCurve = "crv"
        case eccXCoordinate = "x"
        case eccYCoordinate = "y"
        case rsaFirstPrimeFactor = "p"
        case rsaSecondPrimeFactor = "q"
        case rsaFirstFactorCRT = "dp"
        case rsaSecondFactorCRT = "dq"
        case rsaFirstCRTCoefficient = "qi"
        case rsaOtherPRimes = "oth"
        case rsaPrimeFactor = "r"
        case rsaFactorCoefficient = "t"
        case ephemeralPublicKey = "epk"
        case agreementPartyUInfo = "apu"
        case agreementPartyVInfo = "apv"
        case initializationVector = "iv"
        case authenticationTag = "tag"
        case pbes2SaltInput = "p2s"
        case pbes2Count = "p2c"
    }
    
    static func resetToDefault() {
        validator = DefaultJWKValidator()
    }
}
