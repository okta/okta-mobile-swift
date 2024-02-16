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
@testable import AuthFoundation

enum TestError: Error {
    case noBundleResourceFound
}

public extension XCTestCase {
    func mock<T: Decodable & JSONDecodable>(from bundle: Bundle,
                 for filename: String,
                 in folder: String? = nil) throws -> T
    {
        let data = try data(from: bundle, for: filename, in: folder)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        return try decode(type: T.self, string)
    }
    
    func data(for json: String) -> Data {
        return json.data(using: .utf8)!
    }
    
    func data(from bundle: Bundle, for filename: String, in folder: String? = nil) throws -> Data {
        let file = (filename as NSString).deletingPathExtension
        var fileExtension = (filename as NSString).pathExtension
        if fileExtension == "" {
            fileExtension = "json"
        }
        
        guard let url = bundle.url(forResource: file,
                                   withExtension: fileExtension,
                                   subdirectory: folder)
        else {
            throw TestError.noBundleResourceFound
        }
        
        return try data(for: url)
    }
    
    func data(for file: URL) throws -> Data {
        return try Data(contentsOf: file)
    }
    
    func decode<T>(type: T.Type, _ file: URL) throws -> T where T : Decodable & JSONDecodable {
        let json = String(data: try data(for: file), encoding: .utf8)
        return try decode(type: type, json!)
    }

    func decode<T>(type: T.Type, _ file: URL, _ test: ((T) throws -> Void)) throws where T : Decodable & JSONDecodable {
        let json = String(data: try data(for: file), encoding: .utf8)
        try test(try decode(type: type, json!))
    }

    func decode<T>(type: T.Type, _ json: String) throws -> T where T : Decodable & JSONDecodable {
        try decode(type: type, decoder: T.jsonDecoder, json)
    }

    func decode<T>(type: T.Type, _ json: String, _ test: ((T) throws -> Void)) throws where T : Decodable & JSONDecodable {
        try test(try decode(type: type, json))
    }

    func decode<T>(type: T.Type, decoder: JSONDecoder, _ json: String) throws -> T where T : Decodable {
        let jsonData = data(for: json)
        return try decoder.decode(T.self, from: jsonData)
    }
    
    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func perform(queueCount: Int = 5, iterationCount: Int = 10, _ block: @escaping () async throws -> Void) rethrows {
        let queues: [DispatchQueue] = (0..<queueCount).map { queueNumber in
            DispatchQueue(label: "Async queue \(queueNumber)")
        }
        
        let group = DispatchGroup()
        for queue in queues {
            for _ in 0..<iterationCount {
                queue.async {
                    group.enter()
                    Task {
                        try await block()
                        group.leave()
                    }
                }
            }
        }
        
        _ = group.wait(timeout: .short)
    }
    #endif
}
