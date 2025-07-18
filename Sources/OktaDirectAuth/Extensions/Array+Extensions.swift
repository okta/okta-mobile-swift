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

extension Array where Element == GrantType {
    /// The list of all grants that the Direct Authentication SDK supports.
    ///
    /// Currently this library supports the following authentication grant types:
    /// * ``GrantType/password``
    /// * ``GrantType/oob``
    /// * ``GrantType/otp``
    /// * ``GrantType/webAuthn``
    /// * ``GrantType/oobMFA``
    /// * ``GrantType/otpMFA``
    /// * ``GrantType/webAuthnMFA``
    public static var directAuth: [GrantType] {
        [ .password, .oob, .otp, .oobMFA, .otpMFA, .webAuthn, .webAuthnMFA ]
    }
}
