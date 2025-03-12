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

public extension XCTest {
    @discardableResult
    func XCTAssertThrowsErrorAsync<T: Sendable>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (_ error: any Error) -> Void = { _ in }
    ) async -> (any Error)? {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            errorHandler(error)
            return error
        }
        return nil
    }

    func XCTAssertNoThrowAsync<T: Sendable>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) async
    {
        do {
            _ = try await expression()
        } catch {
            XCTFail(message(), file: file, line: line)
        }
    }


    func XCTAssertEqualAsync<T: Sendable>(
        _ expression1: @autoclosure @Sendable () async throws -> T,
        _ expression2: @autoclosure @Sendable () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) async throws where T : Equatable
    {
        async let value1 = expression1()
        async let value2 = expression2()
        let values = try await [value1, value2]

        XCTAssertEqual(values[0], values[1], message(), file: file, line: line)
    }

    func XCTAssertTrueAsync(
        _ expression: @autoclosure @Sendable () async -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) async
    {
        let value = await expression()
        XCTAssertTrue(value, message(), file: file, line: line)
    }

    func XCTAssertFalseAsync(
        _ expression: @autoclosure @Sendable () async -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) async
    {
        let value = await expression()
        XCTAssertFalse(value, message(), file: file, line: line)
    }

    func XCTAssertNilAsync(
        _ expression: @autoclosure @Sendable () async throws -> Any?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) async rethrows
    {
        let value = try await expression()
        XCTAssertNil(value, message(), file: file, line: line)
    }

    func XCTAssertNotNilAsync(
        _ expression: @autoclosure @Sendable () async throws -> Any?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) async rethrows
    {
        let value = try await expression()
        XCTAssertNotNil(value, message(), file: file, line: line)
    }
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
    
    func fileUrl(from bundle: Bundle, for filename: String, in folder: String? = nil) throws -> URL {
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
        
        return url
    }
    
    func data(from bundle: Bundle, for filename: String, in folder: String? = nil) throws -> Data {
        let url = try fileUrl(from: bundle, for: filename, in: folder)
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
}
