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
    /// Object that represents a form of fields associated with a remediation.
    public class Form: NSObject {
        public subscript(index: Int) -> Field? {
            fields[index]
        }
        
        public subscript(name: String) -> Field? {
            var components = name.components(separatedBy: ".")

            let name = components.removeFirst()
            var result = fields.first { $0.name == name }
            if result != nil && !components.isEmpty {
                result = result?.form?[components.joined(separator: ".")]
            }
            
            return result
        }
        
        /// The array of ordered user-visible fields within this form. Each field may also contain nested forms for collections of related fields.
        public let fields: [Field]
        let allFields: [Field]

        init?(fields: [Field]?) {
            guard let fields = fields else { return nil }
            self.allFields = fields
            self.fields = self.allFields.filter { $0.hasVisibleFields }
            super.init()
        }
    }
}
