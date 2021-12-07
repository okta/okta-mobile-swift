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
extension Bundle {
    var resourceBundle: Bundle? {
        guard let resourcePath = resourcePath else { return nil }
        let legacyBuildPath = (bundlePath as NSString).deletingLastPathComponent
        
        var bundle: Bundle?
        for directory in [resourcePath, legacyBuildPath] {
            bundle = try? FileManager.default.contentsOfDirectory(atPath: directory)
                .filter { $0.hasSuffix(".bundle") }
                .compactMap { Bundle(path: "\(directory)/\($0)") }
                .first
            
            if bundle != nil {
                break
            }
        }
        return bundle
    }
}
