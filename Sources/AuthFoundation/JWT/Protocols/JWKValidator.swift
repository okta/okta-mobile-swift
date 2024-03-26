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

/// Protocol used to implement JWK token validation.
///
/// Instances of this protocol may be assigned to ``JWK/validator`` to override the mechanisms used to validate token signatures.
///
/// > Note: A default implementation will be automatically used if this value is not changed.
public protocol JWKValidator {
    /// Verifies the ``JWT`` signature using the supplied ``JWKS`` key set.
    /// - Returns: Returns whether or not signing passes for this token/key combination.
    func validate(token: JWT, using keySet: JWKS) throws -> Bool
}
