//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension Array where Element: FixedWidthInteger {
    /// Generate an array of cryptographically random integers of the given count.
    /// - Parameter count: Number of integers to generate.
    /// - Returns: Array of random integers.
    public static func random(count: Int) -> [Element] {
        var array: [Element] = .init(repeating: 0, count: count)
        (0 ..< count).forEach { array[$0] = Element.random() }
        return array
    }
}

extension Array where Element == UInt8 {
    /// Convenience method for converting an array of integers into a Base64 URL-encoded string.
    public var base64URLEncodedString: String {
        Data(self).base64URLEncodedString
    }
}
