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

extension ProvidesOAuth2Parameters {
    @_documentation(visibility: private)
    public var shouldOverride: Bool { true }
}

extension Dictionary<String, APIRequestArgument> {
    @_documentation(visibility: private)
    @inlinable public mutating func merge(_ oauth2Parameters: ProvidesOAuth2Parameters?) {
        guard let oauth2Parameters = oauth2Parameters,
              let additionalParameters = oauth2Parameters.additionalParameters
        else {
            return
        }
        
        merge(additionalParameters) { oauth2Parameters.shouldOverride ? $1 : $0 }
    }

    @_documentation(visibility: private)
    @inlinable public func merging(_ oauth2Parameters: ProvidesOAuth2Parameters?) -> [Key: Value] {
        var result = self
        result.merge(oauth2Parameters)
        return result
    }
}

extension Dictionary<String, APIRequestArgument>: ProvidesOAuth2Parameters {
    @_documentation(visibility: private)
    public var additionalParameters: [String: any APIRequestArgument]? {
        self
    }
}
