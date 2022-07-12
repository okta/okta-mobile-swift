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

/// Protocol used to implement OpenID token validation.
///
/// Instances of this protocol may be assigned to ``Token/idTokenValidator`` to override the mechanisms used to validate tokens.
///
/// > Note: A default implementation will be automatically used if this value is not changed.
public protocol IDTokenValidator {
    /// The time interval grace period that will be permitted when verifying the ``Token/issuedAt`` value.
    ///
    /// *Default:* 5 minutes.
    var issuedAtGraceInterval: TimeInterval { get set }
    
    /// Validates the claims in the given token, using the supplied issuer and client ID values.
    func validate(token: JWT, issuer: URL, clientId: String, context: IDTokenValidatorContext?) throws
}

/// Protocol used to supply contextual information to a validator.
///
/// The ``IDTokenValidator`` can use this information to enable or disable certain verification checks.
public protocol IDTokenValidatorContext {
    /// The `nonce` value used when beginning the authentication process.
    var nonce: String? { get }
    
    /// The maximum age the token should support when authenticating.
    var maxAge: TimeInterval? { get }
}
