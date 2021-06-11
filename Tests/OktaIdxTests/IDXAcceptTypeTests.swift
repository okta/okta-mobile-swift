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

import XCTest
@testable import OktaIdx

class IDXClientAPIVersion1AcceptTypeTests: XCTestCase {
    func testInvalid() {
        XCTAssertNil(IDXClient.APIVersion1.AcceptType(rawValue: "foo"))
    }
    
    func testFormEncoded() throws {
        let type = IDXClient.APIVersion1.AcceptType(rawValue: "application/x-www-form-urlencoded")
        XCTAssertEqual(type, .formEncoded)
        XCTAssertEqual(try type?.encodedData(with: ["foo": "bar"]), "foo=bar".data(using: .utf8))
        XCTAssertThrowsError(try type?.encodedData(with: ["foo": 1]))
        XCTAssertEqual(type?.stringValue(), "application/x-www-form-urlencoded")
    }
    
    func testIonJson() throws {
        var type = IDXClient.APIVersion1.AcceptType(rawValue: "application/ion+json")
        XCTAssertEqual(type?.stringValue(), "application/ion+json")
        XCTAssertEqual(type, .ionJson(version: nil))
        
        type = IDXClient.APIVersion1.AcceptType(rawValue: "application/ion+json; okta-version=1.0.0")
        XCTAssertEqual(type?.stringValue(), "application/ion+json; okta-version=1.0.0")

        XCTAssertEqual(type, .ionJson(version: "1.0.0"))
        XCTAssertEqual(try type?.encodedData(with: ["foo": "bar"]), "{\"foo\":\"bar\"}".data(using: .utf8))
    }

    func testJson() throws {
        var type = IDXClient.APIVersion1.AcceptType(rawValue: "application/json")
        XCTAssertEqual(type?.stringValue(), "application/json")
        XCTAssertEqual(type, .json(version: nil))
        
        type = IDXClient.APIVersion1.AcceptType(rawValue: "application/json; okta-version=1.0.0")
        XCTAssertEqual(type?.stringValue(), "application/json; okta-version=1.0.0")

        XCTAssertEqual(type, .json(version: "1.0.0"))
        XCTAssertEqual(try type?.encodedData(with: ["foo": "bar"]), "{\"foo\":\"bar\"}".data(using: .utf8))
    }
}
