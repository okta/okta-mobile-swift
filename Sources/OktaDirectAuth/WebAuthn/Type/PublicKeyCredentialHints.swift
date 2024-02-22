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

extension WebAuthn {
    /**
     WebAuthn Relying Parties may use this enumeration to communicate hints to the user-agent about how a request may be best completed.

     - Note: [W3C Reccomendation](https://w3c.github.io/webauthn/#enumdef-publickeycredentialhints)
     */
    public enum PublicKeyCredentialHints: String, Codable {
        /// Indicates that the Relying Party believes that users will satisfy this request with a physical security key.
        case securityKey = "security-key"
        
        /// Indicates that the Relying Party believes that users will satisfy this request with a platform authenticator attached to the client device.
        case clientDevice = "client-device"
        
        /// Indicates that the Relying Party believes that users will satisfy this request with general-purpose authenticators such as smartphones.
        case hybrid
    }
}
