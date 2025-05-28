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
import XCTest
@testable import OktaIdx

extension Data {
    var urlFormEncoded: [String:String?]? {
        guard let string = String(data: self, encoding: .utf8),
              let url = URL(string: "?\(string)"),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems
        else { return nil }

        return queryItems.reduce(into: [String:String?]()) {
            $0[$1.name] = $1.value
        }
    }
    
    func jsonEncoded() throws -> [String:Any?]? {
        try JSONSerialization.jsonObject(with: self) as? [String:Any?]
    }
}

extension String {
    func isBase64URLEncoded() -> Bool {
        let charset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_").inverted
        return (rangeOfCharacter(from: charset) == nil)
    }
}

enum TestError: Error {
    case noBundleResourceFound
}

public extension XCTestCase {
    func data(for json: String) -> Data {
        return json.data(using: .utf8)!
    }
    
    func data(from bundle: Bundle, for filename: String, in folder: String? = nil) throws -> Data {
        let file = (filename as NSString).deletingPathExtension
        var fileExtension = (filename as NSString).pathExtension
        if fileExtension == "" {
            fileExtension = "json"
        }
        
        let subdirectory: String
        if let folder = folder {
            subdirectory = "SampleResponses/\(folder)"
        } else {
            subdirectory = "SampleResponses"
        }
        
        guard let url = bundle.url(forResource: file,
                                   withExtension: fileExtension,
                                   subdirectory: subdirectory)
        else {
            throw TestError.noBundleResourceFound
        }
        
        return try data(for: url)
    }
    
    func data(for file: URL) throws -> Data {
        return try Data(contentsOf: file)
    }
    
    func decode<T>(type: T.Type, _ file: URL) throws -> T where T : Decodable {
        let json = try data(for: file)
        return try decode(type: type, json)
    }

    func decode<T>(type: T.Type, _ file: URL, _ test: ((T) throws -> Void)) throws where T : Decodable {
        let json = try data(for: file)
        try test(try decode(type: type, json))
    }

    func decode<T>(type: T.Type, _ json: String) throws -> T where T : Decodable & JSONDecodable {
        try decode(type: type, json.data(using: .utf8)!)
    }

    func decode<T>(type: T.Type, _ json: String) throws -> T where T : Decodable {
        try decode(type: type, json.data(using: .utf8)!)
    }

    func decode<T>(type: T.Type, _ json: Data) throws -> T where T : Decodable & JSONDecodable {
        try decode(type: type, decoder: T.jsonDecoder, json)
    }

    func decode<T>(type: T.Type, _ json: Data) throws -> T where T : Decodable {
        try decode(type: type, decoder: JSONDecoder(), json)
    }

    func decode<T>(type: T.Type, _ json: Data, _ test: ((T) throws -> Void)) throws where T : Decodable {
        try test(try decode(type: type, json))
    }

    func decode<T>(type: T.Type, decoder: JSONDecoder, _ json: Data) throws -> T where T : Decodable {
        return try decoder.decode(T.self, from: json)
    }
}

enum TestDataSource {
    case file(_ name: String, folder: String? = nil)
    case url(_ fileURL: URL)
    case json(_ json: String)
}

protocol TestResponse {
    static func data(from source: TestDataSource) throws -> Self
}

extension TestResponse where Self : Decodable {
    static func data(from source: TestDataSource) throws -> Self {
        switch source {
        case .file(let name, let folder):
            let fileUrl = Bundle.testResource(folderName: folder, fileName: name)
            return try data(from: .url(fileUrl))
        case .url(let url):
            return try data(from: .json(try String(contentsOf: url)))
        case .json(let json):
            let data = json.data(using: .utf8)!
            return try InteractionCodeFlow.IntrospectRequest.jsonDecoder.decode(Self.self, from: data)
        }
    }
}

extension IonResponse: TestResponse {}
