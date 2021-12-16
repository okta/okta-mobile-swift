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

extension IDXClient.Message {
    /// Represents a collection of messages.
    @objc(IDXMessageCollection)
    public class Collection: NSObject {
        /// Convenience to return the message associated with the given field.
        @objc(messageForField:)
        public func message(for field: Remediation.Form.Field) -> IDXClient.Message? {
            return allMessages.first(where: { $0.field == field })
        }
        
        /// Convenience method to return the message for a field with the given name.
        @objc(messageForFieldNamed:)
        public func message(for fieldName: String) -> IDXClient.Message? {
            return allMessages.first(where: { $0.field?.name == fieldName })
        }
        
        @objc public var allMessages: [IDXClient.Message] {
            guard let nestedMessages = nestedMessages else { return messages }
            return messages + nestedMessages.compactMap { $0.object }
        }
        
        var nestedMessages: [Weak<IDXClient.Message>]?

        let messages: [IDXClient.Message]
        init(messages: [IDXClient.Message]?, nestedMessages: [IDXClient.Message]? = nil) {
            self.messages = messages ?? []
            self.nestedMessages = nestedMessages?.map { Weak(object: $0) }

            super.init()
        }
        
        public override var description: String {
            let logger = DebugDescription(self)
            let components = [logger.address()]

            return logger.brace(components.joined(separator: "; "))
        }
        
        public override var debugDescription: String {
            let logger = DebugDescription(self)
            let components = [
                "\(logger.format(messages.map(\.debugDescription), indent: .zero))"
            ]
            
            return """
            \(description) {
            \(logger.format(components, indent: 4))
            }
            """
        }
    }
}
