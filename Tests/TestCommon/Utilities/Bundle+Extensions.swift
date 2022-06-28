/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
        let bundle = Bundle(for: URLSessionMock.self)
        #if SWIFT_PACKAGE
        let bundleName = "OktaIdx_TestCommon"
        #else
        let bundleName = "TestCommon"
        #endif
        
        var path = bundle.bundleURL
        
        let fm = FileManager.default
        // Handle differences when run in macOS targets.
        if fm.fileExists(atPath: "\(path.path)/Contents/Resources") {
            path.appendPathComponent("Contents/Resources")
        }
        
        #if SWIFT_PACKAGE
        if !fm.fileExists(atPath: "\(path.path)/\(bundleName).bundle") {
            path.deleteLastPathComponent()
        }
        path.appendPathComponent("\(bundleName).bundle")
        #endif
        
        if FileManager.default.fileExists(atPath: "\(path.path)/Contents/Resources") {
            path.appendPathComponent("Contents/Resources")
        }
        
        return path
    }
    
    static func testResource(folderName: String? = nil, fileName: String) -> URL {
        var path = resourcesPath
        
        path.appendPathComponent("SampleResponses")
        if let folderName = folderName {
            path.appendPathComponent(folderName)
        }
        path.appendPathComponent(fileName)
        path.appendPathExtension("json")
        return path
    }
}
