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

/// Protocol used to implement token validation using either the `at_hash` or `ds_hash` properties from an ID token.
///
/// Instances of this protocol may be assigned to ``Token/accessTokenValidator`` or ``Token/deviceSecretValidator`` to override the mechanisms used to validate tokens.
///
/// > Note: A default implementation will automatically be used if this value is not changed.
public protocol TokenHashValidator {
    /// Validates the given access token, using the `at_hash` value from the supplied ID token, if it is present.
    func validate(_ string: String, idToken: JWT) throws
}
