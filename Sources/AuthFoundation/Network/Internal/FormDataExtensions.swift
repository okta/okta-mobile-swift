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

#if os(Linux)
import FoundationNetworking
#endif

extension URLRequest {
    static func oktaURLFormEncodedString(for params: [String: APIRequestArgument]) -> String? {
        func escape(_ str: String) -> String {
            // swiftlint:disable force_unwrapping
            return str.replacingOccurrences(of: "\n", with: "\r\n")
                .addingPercentEncoding(withAllowedCharacters: oktaQueryCharacters)!
                .replacingOccurrences(of: " ", with: "+")
            // swiftlint:enable force_unwrapping
        }

        return params.keys.sorted().compactMap {
            guard let value = params[$0]?.stringValue else { return nil }
            return escape($0) + "=" + escape(value)
        }.joined(separator: "&")
    }
    
    private static let oktaQueryCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.insert(" ")
        allowed.remove("+")
        allowed.remove("/")
        allowed.remove("&")
        allowed.remove("=")
        allowed.remove("?")
        return allowed
    }()
}
