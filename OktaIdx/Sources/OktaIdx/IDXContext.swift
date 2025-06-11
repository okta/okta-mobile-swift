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
import AuthFoundation

extension InteractionCodeFlow {
    /// Object that defines the context for the current authentication session, which is required when a session needs to be resumed.
    public struct Context: AuthenticationContext, IDTokenValidatorContext, Sendable, Codable, Equatable {
        /// The ACR values, if any, which should be requested by the client.
        @ClaimCollection
        public var acrValues: [String]?

        /// The maximum age an ID token can be when authenticating.
        public var maxAge: TimeInterval?

        /// The state value used when initiating the authentication session.
        ///
        /// This value can be used to associate a redirect URI to the associated Context that can be used to resume an authentication session.
        public var state: String

        /// The interaction handle returned from the `interact` response from the server.
        public internal(set) var interactionHandle: String?

        /// Supplies the token used when a user is recovering their account.
        public var recoveryToken: String?

        /// The "nonce" value to send with this authorization request.
        public let nonce: String?

        /// The `PKCE` credentials to use in the authorization request.
        ///
        /// This value may be `nil` on platforms that do not support PKCE.
        public let pkce: PKCE?

        /// Any additional query string parameters you would like to supply to the authorization server.
        public var additionalParameters: [String: any APIRequestArgument]?

        /// Initializer for creating a context with a custom state string.
        /// - Parameters:
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        ///   - maxAge: The maximum age an ID token can be when authenticating.
        ///   - acrValues: The ACR values, if any, which should be requested by the client.
        ///   - additionalParameters: Any additional request parameters you would like to supply to the authorization server.
        public init(recoveryToken: String? = nil,
                    state: String? = nil,
                    maxAge: TimeInterval? = nil,
                    acrValues: ClaimCollection<[String]?> = nil,
                    additionalParameters: [String: any APIRequestArgument]? = nil)
        {
            let nonce = additionalParameters?["nonce"] as? String ?? .nonce()
            let state = state ?? additionalParameters?["state"] as? String ?? UUID().uuidString
            let maxAge = maxAge ?? additionalParameters?.maxAge
            self.init(interactionHandle: nil,
                      recoveryToken: recoveryToken,
                      state: state,
                      pkce: PKCE(),
                      acrValues: acrValues,
                      maxAge: maxAge,
                      nonce: nonce,
                      additionalParameters: additionalParameters?.omitting("nonce", "max_age", "state"))
        }

        @_documentation(visibility: internal)
        public static func == (lhs: InteractionCodeFlow.Context, rhs: InteractionCodeFlow.Context) -> Bool {
            lhs.recoveryToken == rhs.recoveryToken &&
            lhs.state == rhs.state &&
            lhs.pkce == rhs.pkce &&
            lhs.acrValues == rhs.acrValues &&
            lhs.maxAge == rhs.maxAge &&
            lhs.nonce == rhs.nonce &&
            lhs.interactionHandle == rhs.interactionHandle &&
            lhs.additionalParameters?.stringComponents == rhs.additionalParameters?.stringComponents
        }

        init(interactionHandle: String? = nil,
             recoveryToken: String?,
             state: String,
             pkce: PKCE?,
             acrValues: ClaimCollection<[String]?>,
             maxAge: TimeInterval?,
             nonce: String?,
             additionalParameters: [String: any APIRequestArgument]?)
        {
            self.interactionHandle = interactionHandle
            self.recoveryToken = recoveryToken
            self.state = state
            self.pkce = pkce
            self._acrValues = acrValues
            self.maxAge = maxAge
            self.nonce = nonce
            self.additionalParameters = additionalParameters
        }

        enum CodingKeys: String, CodingKey, CaseIterable {
            case interactionHandle
            case recoveryToken
            case state
            case pkce
            case acrValues
            case maxAge
            case nonce
            case additionalParameters
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            interactionHandle = try container.decodeIfPresent(String.self, forKey: .interactionHandle)
            recoveryToken = try container.decodeIfPresent(String.self, forKey: .recoveryToken)
            state = try container.decode(String.self, forKey: .state)
            pkce = try container.decodeIfPresent(PKCE.self, forKey: .pkce)
            _acrValues = try container.decode(ClaimCollection<[String]?>.self, forKey: .acrValues)
            maxAge = try container.decodeIfPresent(TimeInterval.self, forKey: .maxAge)
            nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
            additionalParameters = try container.decodeIfPresent([String: String].self, forKey: .additionalParameters)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(interactionHandle, forKey: .interactionHandle)
            try container.encodeIfPresent(recoveryToken, forKey: .recoveryToken)
            try container.encode(state, forKey: .state)
            try container.encodeIfPresent(pkce, forKey: .pkce)
            try container.encode(_acrValues, forKey: .acrValues)
            try container.encodeIfPresent(maxAge, forKey: .maxAge)
            try container.encodeIfPresent(nonce, forKey: .nonce)
            try container.encodeIfPresent(additionalParameters?.mapValues(\.stringValue), forKey: .additionalParameters)
        }

        @_documentation(visibility: internal)
        public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
            var result = additionalParameters ?? [:]

            switch category {
            case .authorization:
                result["state"] = state
                result["response_type"] = "code"
                result["nonce"] = nonce
                result["recovery_token"] = recoveryToken

                if let maxAge {
                    result["max_age"] = Int(maxAge).stringValue
                }

                if let values = $acrValues.rawValue {
                    result["acr_values"] = values
                }

                if let pkce {
                    result["code_challenge"] = pkce.codeChallenge
                    result["code_challenge_method"] = pkce.method
                }

            case .token:
                if let pkce = pkce {
                    result["code_verifier"] = pkce.codeVerifier
                }

            case .configuration, .resource, .other: break
            }

            return result
                .compactMapValues { $0 }
                .nilIfEmpty
        }
    }
}
