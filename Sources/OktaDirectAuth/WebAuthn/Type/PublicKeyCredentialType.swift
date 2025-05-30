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
     This member contains the type of the public key credential the caller is referring to.
     
     - Note: [W3C Reccomendation](https://www.w3.org/TR/webauthn/#dom-publickeycredentialdescriptor-type)
     */
    public enum PublicKeyCredentialType: String, Sendable, Codable, Equatable {
        /// Descripes a public key credential type.
        case publicKey = "public-key"
    }
}
