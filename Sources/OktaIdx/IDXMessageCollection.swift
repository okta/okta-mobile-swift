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
import AuthFoundation

extension Response.Message {
    /// Represents a collection of messages.
    public class Collection: Equatable, Hashable {
        /// Convenience to return the message associated with the given field.
        public func message(for field: Remediation.Form.Field) -> Response.Message? {
            return allMessages.first(where: { $0.field == field })
        }
        
        /// Convenience method to return the message for a field with the given name.
        public func message(for fieldName: String) -> Response.Message? {
            return allMessages.first(where: { $0.field?.name == fieldName })
        }
        
        /// All messages within this collection, and all nested messages.
        public var allMessages: [Response.Message] {
            return messages + nestedMessages.compactMap { $0 }
        }
        
        @WeakCollection
        var nestedMessages: [Response.Message?] = []

        let messages: [Response.Message]
        init(messages: [Response.Message]?, nestedMessages: [Response.Message]? = nil) {
            self.messages = messages ?? []
            self.nestedMessages = nestedMessages ?? []
        }
        
        public static func == (lhs: Collection, rhs: Collection) -> Bool {
            lhs.messages == rhs.messages &&
            lhs.nestedMessages == rhs.nestedMessages
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(messages)
            hasher.combine(nestedMessages)
        }
    }
}
