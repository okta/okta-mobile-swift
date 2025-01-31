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

extension String {
    var base64URLDecoded: String {
        var result = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while result.count % 4 != 0 {
            result.append(contentsOf: "=")
        }

        return result
    }
    
    @_documentation(visibility: internal)
    public static func nonce(length: UInt = 16) -> String {
        [UInt8].random(count: Int(length)).base64URLEncodedString
    }
    
    @_documentation(visibility: internal)
    public var snakeCase: String {
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: "([a-z])([A-Z])")
        let range = NSRange(location: 0, length: self.count)
        let snakeCased = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
        return snakeCased.lowercased()
    }
}
