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

extension Dictionary where Key == String, Value == String {
    @_documentation(visibility: internal)
    public var percentQueryEncoded: String {
        var cs = CharacterSet.urlQueryAllowed
        cs.remove("+")

        return compactMap { (key, value) in
            guard let key = key.addingPercentEncoding(withAllowedCharacters: cs),
                  let value = value.addingPercentEncoding(withAllowedCharacters: cs)
            else {
                return nil
            }
            
            return key + "=" + value
        }.sorted().joined(separator: "&")
    }
}

extension Dictionary where Key == String, Value == (any APIRequestArgument)? {
    @_documentation(visibility: internal)
    public var percentQueryEncoded: String {
        compactMapValues { $0?.stringValue }.percentQueryEncoded
    }
}
