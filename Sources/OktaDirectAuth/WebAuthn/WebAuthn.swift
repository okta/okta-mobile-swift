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

/// Exposes the types and classes used to authenticate using WebAuthn.
///
/// Example:
///
/// ```swift
/// let challengeStatus = try await flow.start("user@example.com", with: .webAuthn)
/// guard case let .webAuthn(let request) = challengeStatus else { return }
///
/// // Supply challenge request values to your authenticator
/// let responseStatus = try await flow.resume(
///     challengeStatus,
///     with: .webAuthnAssertion(.init(
///         clientDataJSON: authJson,
///         authenticatorData: authData,
///         signature: authSignature,
///         userHandle: nil)
///     )
/// )
/// ```
public struct WebAuthn {
    /// Represents the credential challenge returned from the server when a WebAuthn authentication is initiated.
    public struct CredentialRequestOptions: Codable {
        /// The public key request options supplied to the client from the server.
        public let publicKey: WebAuthn.PublicKeyCredentialRequestOptions
        
        /// Defines additional authenticator enrollment information supplied by the server.
        public let authenticatorEnrollments: [AuthenticatorEnrollment]?

        /// Defines additional authenticator enrollment information supplied by the server.
        public struct AuthenticatorEnrollment: Codable {
            /// The ID supplied from the server representing this credential.
            ///
            /// **Note:** This should be identical to the ``WebAuthn/PublicKeyCredentialRequestOptions/rpID`` value.
            public let credentialId: String
            
            /// The human-readable display name for this authenticator.
            public let displayName: String
            
            /// Additional profile information related to this authenticator.
            public let profile: [String: String]
        }
    }
    
    /// Defines the set of data expected from the client in response to an authenticator challenge.
    ///
    /// This value should be supplied to the ``DirectAuthenticationFlow/SecondaryFactor/webAuthnAssertion`` type.
    public struct AuthenticatorAssertionResponse: Codable, Equatable {
        /// The client data JSON response, represented as a string.
        public let clientDataJSON: String
        
        /// The authenticator data for the response.
        public let authenticatorData: String
        
        /// The signature generated from the authenticator.
        public let signature: String
        
        /// The optional user handle to supply to the server, typically if the resident key is enabled.
        public let userHandle: String?
    }
}

extension WebAuthn.CredentialRequestOptions: JSONDecodable {
    public static var jsonDecoder = JSONDecoder()
}
