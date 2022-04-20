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

import XCTest
@testable import AuthFoundation

final class APIContentTypeTests: XCTestCase {
    func testRawValueConstructor() {
        XCTAssertEqual(APIContentType(rawValue: "application/json"), .json)
        XCTAssertEqual(APIContentType(rawValue: "application/x-www-form-urlencoded"), .formEncoded)
        XCTAssertEqual(APIContentType(rawValue: "application/ion+json"), .other("application/ion+json"))
    }

    func testRawValue() {
        XCTAssertEqual(APIContentType(rawValue: "application/json")?.rawValue,
                       "application/json; charset=UTF-8")
        XCTAssertEqual(APIContentType(rawValue: "application/json; charset=UTF-8")?.rawValue,
                       "application/json; charset=UTF-8")
        XCTAssertEqual(APIContentType(rawValue: "application/json; okta-version=1.0.0")?.rawValue,
                       "application/json; okta-version=1.0.0")

        XCTAssertEqual(APIContentType(rawValue: "application/x-www-form-urlencoded")?.rawValue,
                       "application/x-www-form-urlencoded; charset=UTF-8")
        XCTAssertEqual(APIContentType(rawValue: "application/x-www-form-urlencoded; charset=UTF-8")?.rawValue,
                       "application/x-www-form-urlencoded; charset=UTF-8")
    }

    func testUnderlyingType() {
        XCTAssertEqual(APIContentType(rawValue: "application/json")?.underlyingType, .json)
        XCTAssertEqual(APIContentType(rawValue: "application/json; encoding=UTF-8")?.underlyingType, .json)
        XCTAssertEqual(APIContentType(rawValue: "application/json; okta-version=1.0.0")?.underlyingType, .json)
        
        XCTAssertEqual(APIContentType(rawValue: "application/x-www-form-urlencoded")?.underlyingType, .formEncoded)
        XCTAssertEqual(APIContentType(rawValue: "application/x-www-form-urlencoded; encoding=UTF-8")?.underlyingType, .formEncoded)

        XCTAssertEqual(APIContentType(rawValue: "application/ion+json")?.underlyingType, .json)
    }
    
    func testJsonEncodedData() throws {
        let data = try XCTUnwrap(APIContentType.json.encodedData(with: ["string": "value", "bool": true, "int": 6]))
        XCTAssertEqual(String(data: data, encoding: .utf8),
                       "{\"bool\":true,\"int\":6,\"string\":\"value\"}")
    }

    func testFormEncodedData() throws {
        let data = try XCTUnwrap(APIContentType.formEncoded.encodedData(with: ["string": "value", "bool": true, "int": 6]))
        XCTAssertEqual(String(data: data, encoding: .utf8),
                       "bool=true&int=6&string=value")
    }
}
