//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension WebAuthn {
    /**
     The PublicKeyCredentialRequestOptions dictionary supplies get() with the data it needs to generate an assertion. Its challenge member MUST be present, while its other members are OPTIONAL.
     
     - Note: [W3C Reccomendation](https://www.w3.org/TR/webauthn/#dictionary-assertion-options)
     */
    public struct PublicKeyCredentialRequestOptions: Codable {
        /// This member specifies a challenge that the authenticator signs, along with other data, when producing an authentication assertion. See the § 13.4.3 Cryptographic Challenges security consideration.
        public let challenge: String
        
        /// Specifies the RP ID claimed by the Relying Party. The client MUST verify that the Relying Party's origin matches the scope of this RP ID. The authenticator MUST verify that this RP ID exactly equals the rpId of the credential to be used for the authentication ceremony.
        public internal(set) var rpID: String?

        /// Used by the client to find authenticators eligible for this authentication ceremony.
        public let allowCredentials: [PublicKeyCredentialDescriptor]?

        /// Specifies a time that the Relying Party is willing to wait for the call to complete.
        public let timeout: TimeInterval?
        
        /// Specifies the Relying Party's requirements regarding user verification. Eligible authenticators are filtered to only those capable of satisfying this requirement.
        public let userVerification: UserVerificationRequirement?
        
        /// Guides the user agent in interacting with the user.
        public let hints: [PublicKeyCredentialHints]?

        /// The Relying Party MAY use this to provide client extension inputs requesting additional processing by the client and authenticator.
        public let extensions: [String: Any?]?

        enum CodingKeys: String, CodingKey {
            case allowCredentials
            case challenge
            case extensions
            case rpID
            case timeout
            case hints
            case userVerification
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            allowCredentials = try container.decodeIfPresent([PublicKeyCredentialDescriptor].self, forKey: .allowCredentials)
            challenge = try container.decode(String.self, forKey: .challenge)
            rpID = try container.decodeIfPresent(String.self, forKey: .rpID)
            hints = try container.decodeIfPresent([PublicKeyCredentialHints].self, forKey: .hints)
            userVerification = try container.decodeIfPresent(UserVerificationRequirement.self, forKey: .userVerification)

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
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(challenge, forKey: .challenge)
            try container.encodeIfPresent(allowCredentials, forKey: .allowCredentials)
            try container.encodeIfPresent(rpID, forKey: .rpID)
            try container.encodeIfPresent(hints, forKey: .hints)
            
            if let timeout = timeout {
                try container.encode(UInt64(timeout * 1000), forKey: .timeout)
            }
            
            if let extensions = extensions {
                try container.encode(try extensions.mapValues({ try JSONValue($0) }), forKey: .extensions)
            }
        }
    }
}
