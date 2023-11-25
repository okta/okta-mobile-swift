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

extension Capability {
    /// Capability to access data related to Duo
    public class Duo: AuthenticatorCapability {
        public let host: String
        public let signedToken: String
        public let script: String
        public var signatureData: String?
        
        public func willProceed(to remediation: Remediation) {
            guard remediation.authenticators.contains(where: {
                $0.type == .app && $0.methods?.contains(.duo) ?? false
            }),
                  let credentialsField = remediation.form["credentials"],
                  let signatureField = credentialsField.form?.allFields.first(where: { $0.name == "signatureData" })
            else {
                return
            }
            
            signatureField.value = signatureData
        }
        
        init(host: String, signedToken: String, script: String, signatureData: String? = nil) {
            self.host = host
            self.signedToken = signedToken
            self.script = script
            self.signatureData = signatureData
        }
    }
}
