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
     This dictionary contains the attributes that are specified by a caller when referring to a public key credential as an input parameter to the create() or get() methods. It mirrors the fields of the PublicKeyCredential object returned by the latter methods.
     
     - Note: [W3C Reccomendation](https://www.w3.org/TR/webauthn/#dictionary-credential-descriptor)
     */
    public struct PublicKeyCredentialDescriptor: Codable {
        /// This member contains the credential ID of the public key credential the caller is referring to.
        public let id: String
        
        /// This member contains the type of the public key credential the caller is referring to.
        public let type: PublicKeyCredentialType
        
        /// This OPTIONAL member contains a hint as to how the client might communicate with the managing authenticator of the public key credential the caller is referring to. The values SHOULD be members of AuthenticatorTransport but client platforms MUST ignore unknown values.
        public let transports: [AuthenticatorTransport]?
    }
}
