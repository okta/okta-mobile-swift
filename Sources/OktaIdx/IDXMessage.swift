//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension IDXClient {
    /// Represents messages sent from the server to indicate error or warning conditions related to responses or form values.
    @objc(IDXMessage)
    public final class Message: NSObject {
        /// Enumeration describing the type of message.
        @objc public enum Severity: Int {
            case error
            case info
            case unknown
        }
        
        /// The type of message received from the server
        @objc public let type: Severity
        
        /// A localization key representing this message.
        ///
        /// This allows the text represented by this message to be customized or localized as needed.
        @objc public let localizationKey: String?
        
        /// The default text for this message.
        @objc public let message: String
        
        /// The field where this error occurred, or `nil` if this message is not scoped to a particular field.
        @objc weak internal(set) public var field: IDXClient.Remediation.Form.Field?
        
        internal init(type: String,
                      localizationKey: String?,
                      message: String)
        {
            self.type = Severity(string: type)
            self.localizationKey = localizationKey
            self.message = message
            
            super.init()
        }
    }
}
