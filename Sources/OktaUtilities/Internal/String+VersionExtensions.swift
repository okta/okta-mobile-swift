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

extension CustomStringConvertible {
    @inlinable
    func with(suffix: (any CustomStringConvertible)? = nil, _ additionalComponents: String?...) -> String {
        var result = self.description
        if let suffix = suffix {
            result.append("/\(suffix.description)")
        }

        guard !additionalComponents.isEmpty else {
            return result
        }
        
        let components: [String] = additionalComponents
            .filter { $0?.isEmpty == false }
            .compactMap({ $0 })
        guard !components.isEmpty else {
            return result
        }
        
        result.append(" (\(components.joined(separator: "; ")))")
        return result
    }
}
