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

extension URL {
    @_documentation(visibility: internal)
    @inlinable
    public init?(string value: String?) throws {
        guard let value = value else {
            return nil
        }

        guard let result = URL(string: value) else {
            throw OAuth2Error.invalidUrl
        }
        
        self = result
    }

    @_documentation(visibility: internal)
    @inlinable
    public init(requiredString value: String?) throws {
        guard let value = value,
              let result = URL(string: value)
        else {
            throw OAuth2Error.invalidUrl
        }
        
        self = result
    }
}
