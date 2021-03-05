/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

extension Bundle {
    static var resourcesPath: URL {
        #if os(macOS)
        if let bundle = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") }) {
            return bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("OktaIdx_OktaIdxTests.bundle")
        }
        fatalError("Couldn't find the products directory")
        #else
        return Bundle(for: IDXClientAPIv1Mock.self).bundleURL
        #endif
    }
    
    static func testResource(folderName: String? = nil, fileName: String) -> URL {
        var path = resourcesPath.appendingPathComponent("Resources")
        if let folderName = folderName {
            path.appendPathComponent(folderName)
        }
        path.appendPathComponent(fileName)
        path.appendPathExtension("json")
        return path
    }
}
