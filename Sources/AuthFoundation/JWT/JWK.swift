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
public struct JWK: Codable, Equatable, Identifiable {
    public let type: KeyType
    public let id: String?
    public let usage: Usage
    public let algorithm: Algorithm?
    public let rsaModulus: String?
    public let rsaExponent: String?
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(KeyType.self, forKey: .keyType)
        id = try container.decodeIfPresent(String.self, forKey: .keyId)
        usage = try container.decode(Usage.self, forKey: .usage)
        algorithm = try container.decodeIfPresent(JWK.Algorithm.self, forKey: .algorithm)
        rsaModulus = try container.decodeIfPresent(String.self, forKey: .rsaModulus)
        rsaExponent = try container.decodeIfPresent(String.self, forKey: .rsaExponent)
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
        case keyOperations = "key_ops"
        case certificateUrl = "x5u"
        case certificateChain = "x5c"
        case certificateThumbprint = "x5t"
        case certificateSHA256Thumbprint = "x5t#S256"
        case privateKey = "d"
        case eccCurve = "crv"
        case eccXCoordinate = "x"
        case eccYCoordinate = "y"
        case rsaModulus = "n"
        case rsaExponent = "e"
        case rsaFirstPrimeFactor = "p"
        case rsaSecondPrimeFactor = "q"
        case rsaFirstFactorCRT = "dp"
        case rsaSecondFactorCRT = "dq"
        case rsaFirstCRTCoefficient = "qi"
        case rsaOtherPRimes = "oth"
        case rsaPrimeFactor = "r"
        case rsaFactorCoefficient = "t"
    }
}
