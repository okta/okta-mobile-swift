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

/// Indicates a type can be consumed from a ``HasClaims`` object and converted to the indicated type.
public protocol ClaimConvertable {
    /// Converts the given `Any` value to an instance of the conforming type's class, otherwise return `nil` if this cannot be done.
    /// - Parameter value: The value to convert.
    /// - Returns: The converted value, or `nil`.
    static func convert(from value: Any?) -> Self?
}

extension ClaimConvertable {
    @_documentation(visibility: private)
    public static func convert(from value: Any?) -> Self? {
        value as? Self
    }
}
