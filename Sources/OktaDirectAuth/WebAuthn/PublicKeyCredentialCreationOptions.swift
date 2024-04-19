//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

struct AdditionalValuesCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?
    init?(intValue: Int) {
        return nil
    }
}

extension KeyedDecodingContainer where Key == AdditionalValuesCodingKeys {
    func decodeUnkeyedContainer<T: CodingKey>(exclude keyedBy: T.Type) -> [String: Any] {
        var data = [String: Any]()
    
        for key in allKeys {
            if keyedBy.init(stringValue: key.stringValue) == nil {
                if let value = try? decode(String.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Bool.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Int.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Double.self, forKey: key) {
                    data[key.stringValue] = value
                }
                else if let value = try? decode(Float.self, forKey: key) {
                    data[key.stringValue] = value
                }
            }
        }
    
        return data
    }
}

extension KeyedEncodingContainer where Key == AdditionalValuesCodingKeys {
    
}

extension WebAuthn {
    public struct PublicKeyCredentialRpEntity: Codable {
        public let name: String?
        public let id: String?
    }
    
    public struct PublicKeyCredentialUserEntity: Codable {
        public let id: String
        public let name: String
        public let displayName: String
    }
    
    public struct PublicKeyCredentialParameters: Codable {
        public let type: String
        public let alg: Int32
    }

    public struct AuthenticatorSelectionCriteria: Codable {
        public let authenticatorAttachment: AuthenticatorAttachment?
        public let residentKey: ResidentKeyRequirement?
        public let requireResidentKey: Bool
        public let userVerification: UserVerificationRequirement?
    }

    public struct PublicKeyCredentialCreationOptions: Codable, CustomStringConvertible {
        public let rp: PublicKeyCredentialRpEntity
        public let user: PublicKeyCredentialUserEntity
        public let challenge: String
        public let pubKeyCredParams: [PublicKeyCredentialParameters]
        public let timeout: TimeInterval?
        public let excludeCredentials: [PublicKeyCredentialDescriptor]?
        public let authenticatorSelection: AuthenticatorSelectionCriteria?
        public let attestation: AttestationConveyancePreference?
        public let extensions: [String: Any?]?
        public let additionalValues: [String: JSONValue]?
        
        enum CodingKeys: CodingKey {
            var intValue: Int? {
                if case let .otherInt(intValue) = self {
                    return intValue
                }
                return nil
            }
            
            init?(intValue: Int) {
                self = .otherInt(key: intValue)
            }
            
            case rp
            case user
            case challenge
            case pubKeyCredParams
            case timeout
            case excludeCredentials
            case authenticatorSelection
            case attestation
            case extensions
            case other(key: String)
            case otherInt(key: Int)

            init?(stringValue: String) {
                switch stringValue {
                case "rp": self = .rp
                case "user": self = .user
                case "challenge": self = .challenge
                case "pubKeyCredParams": self = .pubKeyCredParams
                case "timeout": self = .timeout
                case "excludeCredentials": self = .excludeCredentials
                case "authenticatorSelection": self = .authenticatorSelection
                case "attestation": self = .attestation
                case "extensions": self = .extensions
                default: self = .other(key: stringValue)
                }
            }
            
            var stringValue: String {
                switch self {
                case .rp: return "rp"
                case .user: return "user"
                case .challenge: return "challenge"
                case .pubKeyCredParams: return "pubKeyCredParams"
                case .timeout: return "timeout"
                case .excludeCredentials: return "excludeCredentials"
                case .authenticatorSelection: return "authenticatorSelection"
                case .attestation: return "attestation"
                case .extensions: return "extensions"
                case .other(let key): return key
                case .otherInt(key: _): return ""
                }
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            rp = try container.decode(PublicKeyCredentialRpEntity.self, forKey: .rp)
            user = try container.decode(PublicKeyCredentialUserEntity.self, forKey: .user)
            challenge = try container.decode(String.self, forKey: .challenge)
            pubKeyCredParams = try container.decode([PublicKeyCredentialParameters].self, forKey: .pubKeyCredParams)
            excludeCredentials = try container.decodeIfPresent([PublicKeyCredentialDescriptor].self, forKey: .excludeCredentials)
            authenticatorSelection = try container.decodeIfPresent(AuthenticatorSelectionCriteria.self, forKey: .authenticatorSelection)
            attestation = try container.decodeIfPresent(AttestationConveyancePreference.self, forKey: .attestation)

            if let interval = try container.decodeIfPresent(UInt64.self, forKey: .timeout) {
                timeout = Double(interval) / 1000.0
            } else {
                timeout = nil
            }

            if let jsonValues = try container.decodeIfPresent([String: JSONValue].self, forKey: .extensions) {
                extensions = jsonValues.mapValues({ $0.anyValue })
            } else {
                extensions = nil
            }
            
            self.additionalValues = try container.allKeys.reduce(into: [String: JSONValue](), { partialResult, item in
                if case let .other(key) = item {
                    partialResult[key] = try container.decode(JSONValue.self, forKey: item)
                }
            })
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(rp, forKey: .rp)
            try container.encode(user, forKey: .user)
            try container.encode(challenge, forKey: .challenge)
            try container.encode(pubKeyCredParams, forKey: .pubKeyCredParams)
            try container.encodeIfPresent(excludeCredentials, forKey: .excludeCredentials)
            try container.encodeIfPresent(authenticatorSelection, forKey: .authenticatorSelection)
            try container.encodeIfPresent(attestation, forKey: .attestation)
            
            if let timeout = timeout {
                try container.encode(UInt64(timeout * 1000), forKey: .timeout)
            }
            
            if let extensions = extensions {
                try container.encode(try extensions.mapValues({ try JSONValue($0) }), forKey: .extensions)
            }
            
            if let additionalValues = additionalValues {
                for (key, value) in additionalValues {
                    try container.encode(value, forKey: .other(key: key))
                }
            }
        }
        
        public var description: String {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(self) else {
                return ""
            }
            
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
}
