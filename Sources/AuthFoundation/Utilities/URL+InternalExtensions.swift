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
    // Workaround to address a known bug with URL.appendingPathComponent on Linux.
    // https://github.com/apple/swift-corelibs-foundation/issues/4849
    @inlinable
    func appendingComponent(_ component: String) -> URL {
        // swiftlint:disable force_unwrapping
        #if canImport(FoundationNetworking)
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        if !components.path.hasSuffix("/") {
            components.path.append("/")
        }
        components.path.append(component)
        return components.url!
        #else
        var result = self
        result.appendPathComponent(component)
        return result
        #endif
        // swiftlint:enable force_unwrapping
    }
    
    @inlinable var appendingDiscoveryURL: URL {
        var relativeURL = self
        
        // Ensure the base URL contains a trailing slash in its path, so request paths can be safely appended.
        if !relativeURL.lastPathComponent.isEmpty {
            relativeURL = relativeURL.appendingComponent("")
        }
        
        return relativeURL.appendingComponent(".well-known/openid-configuration")
    }
}
