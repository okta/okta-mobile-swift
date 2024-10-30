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

#if canImport(JWT)
@testable import JWT

#if canImport(APIClient)
import APIClient
#endif

public extension XCTestCase {
    func mock<T: Decodable & JSONDecodable>(filename: String) throws -> T {
        let data = try data(filename: filename)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        return try decode(type: T.self, string)
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
}
#endif
