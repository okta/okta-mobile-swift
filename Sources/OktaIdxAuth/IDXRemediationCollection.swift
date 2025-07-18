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

extension Remediation {
    /// Represents a collection of remediation options.
    public final class Collection: Sendable, Equatable, Hashable {
        /// Returns a remediation based on its string name.
        public subscript(name: String) -> Remediation? {
            remediations.first { $0.name == name }
        }
        
        /// Returns a remediation based on its type.
        public subscript(type: Remediation.RemediationType) -> Remediation? {
            remediations.first { $0.type == type }
        }
        
        @_documentation(visibility: internal)
        public static func == (lhs: Remediation.Collection, rhs: Remediation.Collection) -> Bool {
            lhs.remediations == rhs.remediations
        }

        @_documentation(visibility: internal)
        public func hash(into hasher: inout Hasher) {
            hasher.combine(remediations)
        }

        let remediations: [Remediation]
        
        init(remediations: [Remediation]?) {
            self.remediations = remediations ?? []
        }
    }
}
