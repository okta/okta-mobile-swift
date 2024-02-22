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
     A WebAuthn Relying Party may require user verification for some of its operations but not for others, and may use this type to express its needs.
     
     - Note: [W3C Reccomendation](https://www.w3.org/TR/webauthn/#enum-userVerificationRequirement)
     */
    public enum UserVerificationRequirement: String, Codable {
        /// This value indicates that the Relying Party requires user verification for the operation and will fail the operation if the response does not have the UV flag set.
        case required
        
        /// This value indicates that the Relying Party prefers user verification for the operation if possible, but will not fail the operation if the response does not have the UV flag set.
        case preferred
        
        /// This value indicates that the Relying Party does not want user verification employed during the operation.
        case discouraged
    }
}
