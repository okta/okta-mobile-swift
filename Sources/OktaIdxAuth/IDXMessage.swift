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

#if !COCOAPODS
import CommonSupport
#endif

#if !COCOAPODS
import CommonSupport
#endif

extension Response {
    /// Represents messages sent from the server to indicate error or warning conditions related to responses or form values.
    public final class Message: Sendable, Equatable, Hashable {
        /// Enumeration describing the type of message.
        public enum Severity: Sendable, Equatable, Hashable {
            case error
            case info
            case unknown
        }
        
        /// The type of message received from the server
        public let type: Severity
        
        /// A localization key representing this message.
        ///
        /// This allows the text represented by this message to be customized or localized as needed.
        public let localizationKey: String?
        
        /// The default text for this message.
        public let message: String
        
        /// The field where this error occurred, or `nil` if this message is not scoped to a particular field.
        public internal(set) var field: Remediation.Form.Field? {
            get { lock.withLock { _field } }
            set { lock.withLock { _field = newValue } }
        }

        @_documentation(visibility: internal)
        public static func == (lhs: Response.Message, rhs: Response.Message) -> Bool {
            lhs.type == rhs.type &&
            lhs.localizationKey == rhs.localizationKey &&
            lhs.message == rhs.message &&
            lhs.field === rhs.field
        }
        
        @_documentation(visibility: internal)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(localizationKey)
            hasher.combine(message)
            hasher.combine(field?.name)
        }

        nonisolated(unsafe) private weak var _field: Remediation.Form.Field?
        private let lock = Lock()
        internal init(type: String,
                      localizationKey: String?,
                      message: String)
        {
            self.type = Severity(string: type)
            self.localizationKey = localizationKey
            self.message = message
        }
    }
}
