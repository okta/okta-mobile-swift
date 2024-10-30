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
import XCTest

enum TestError: Error {
    case noBundleResourceFound
}

public extension Bundle {
    func nestedBundles(suffixes: [String] = ["bundle", "xctest"]) -> [Bundle] {
        var result: [Bundle] = [self]
        
        guard let resourcePath = resourcePath,
              let enumerator = FileManager.default.enumerator(atPath: resourcePath)
        else {
            return result
        }
        
        for case let path as String in enumerator {
            guard suffixes.contains(where: { path.range(of: ".\($0)")?.isEmpty == false }),
                  let bundle = Bundle(path: "\(resourcePath)/\(path)"),
                  bundle.infoDictionary?["CFBundlePackageType"] as? String == "BNDL",
                  !result.contains(where: { $0.bundleIdentifier == bundle.bundleIdentifier })
            else {
                continue
            }
            
            result.append(contentsOf: bundle.nestedBundles(suffixes: suffixes))
        }
        
        return result
    }
}

public extension XCTestCase {
    func data(for json: String) -> Data {
        return json.data(using: .utf8)!
    }
    
    func data(forClass testClass: XCTestCase.Type? = nil, filename: String, matching bundleName: String? = nil) throws -> Data {
        let testClass = testClass ?? Self.self
        return try data(from: Bundle(for: testClass), filename: filename, matching: bundleName)
    }
    
    func data(from bundle: Bundle, filename: String, matching bundleName: String? = nil) throws -> Data {
        let file = (filename as NSString).deletingPathExtension
        var fileExtension = (filename as NSString).pathExtension
        if fileExtension == "" {
            fileExtension = "json"
        }
        
        var bundles = bundle.nestedBundles()
        if let bundleName = bundleName {
            bundles = bundles.filter({ $0.bundleIdentifier?.range(of: bundleName)?.isEmpty == false })
        }
        
        guard let url = bundles.compactMap({ $0.url(forResource: file, withExtension: fileExtension) }).first
        else {
            throw TestError.noBundleResourceFound
        }
        
        return try data(for: url)
    }
    
    func data(for file: URL) throws -> Data {
        return try Data(contentsOf: file)
    }

    func decode<T>(type: T.Type, decoder: JSONDecoder, _ json: String) throws -> T where T : Decodable {
        let jsonData = data(for: json)
        return try decoder.decode(T.self, from: jsonData)
    }
    
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func perform(queueCount: Int = 5, iterationCount: Int = 10, _ block: @Sendable @escaping () async throws -> Void) rethrows {
        let queues: [DispatchQueue] = (0..<queueCount).map { queueNumber in
            DispatchQueue(label: "Async queue \(queueNumber)")
        }
        
        let group = DispatchGroup()
        for queue in queues {
            for _ in 0..<iterationCount {
                group.enter()
                queue.async {
                    Task {
                        try await block()
                        group.leave()
                    }
                }
            }
        }
        
        _ = group.wait(timeout: .short)
    }
    
    func sleep(for duration: TimeInterval) {
        let sleepExpectation = expectation(description: "Sleep for \(duration) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            sleepExpectation.fulfill()
        }
        wait(for: [sleepExpectation], timeout: duration + 0.1)
    }
}
