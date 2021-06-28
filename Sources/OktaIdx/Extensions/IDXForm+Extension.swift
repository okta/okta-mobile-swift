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

extension IDXClient.Remediation.Form: Collection {
    public typealias Index = Int
    public typealias Element = IDXClient.Remediation.Form.Field

    public var startIndex: Index {
        fields.startIndex
    }
    
    public var endIndex: Index {
        fields.endIndex
    }

    public subscript(index: Index) -> Element {
        fields[index]
    }
    
    public func index(after i: Index) -> Index {
        fields.index(after: i)
    }
}
