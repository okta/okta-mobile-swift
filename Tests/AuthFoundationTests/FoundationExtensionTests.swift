//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import TestCommon

final class FoundationExtensionTests: XCTestCase {
    func testStringSnakeCase() throws {
        XCTAssertEqual("clientId".snakeCase, "client_id")
        XCTAssertEqual("clientId".camelCase, "clientId")
        XCTAssertEqual("clientId".pascalCase, "ClientId")

        XCTAssertEqual("theValue".snakeCase, "the_value")
        XCTAssertEqual("theValue".camelCase, "theValue")
        XCTAssertEqual("theValue".pascalCase, "TheValue")

        XCTAssertEqual("Awesome".snakeCase, "awesome")
        XCTAssertEqual("Awesome".camelCase, "awesome")
        XCTAssertEqual("Awesome".pascalCase, "Awesome")

        XCTAssertEqual("version1Response".snakeCase, "version_1_response")
        XCTAssertEqual("version1Response".camelCase, "version1Response")
        XCTAssertEqual("version1Response".pascalCase, "Version1Response")

        XCTAssertEqual("Version1Response".snakeCase, "version_1_response")
        XCTAssertEqual("Version1Response".camelCase, "version1Response")
        XCTAssertEqual("Version1Response".pascalCase, "Version1Response")

        XCTAssertEqual("this_is_snake_case".snakeCase, "this_is_snake_case")
        XCTAssertEqual("this_is_snake_case".camelCase, "thisIsSnakeCase")
        XCTAssertEqual("this_is_snake_case".pascalCase, "ThisIsSnakeCase")

        XCTAssertEqual("__prefixedWithUnderscores".snakeCase, "__prefixed_with_underscores")
        XCTAssertEqual("__prefixedWithUnderscores".camelCase, "prefixedWithUnderscores")
        XCTAssertEqual("__prefixedWithUnderscores".pascalCase, "PrefixedWithUnderscores")

        XCTAssertEqual("isHTTPResponse".snakeCase, "is_http_response")
        XCTAssertEqual("isHTTPResponse".camelCase, "isHTTPResponse")
        XCTAssertEqual("isHTTPResponse".pascalCase, "IsHTTPResponse")

        XCTAssertEqual("is400HTTPResponse".snakeCase, "is_400_http_response")
        XCTAssertEqual("is400HTTPResponse".camelCase, "is400HTTPResponse")
        XCTAssertEqual("is400HTTPResponse".pascalCase, "Is400HTTPResponse")

        XCTAssertEqual("isHTTP400Response".snakeCase, "is_http_400_response")
        XCTAssertEqual("isHTTP400Response".camelCase, "isHTTP400Response")
        XCTAssertEqual("isHTTP400Response".pascalCase, "IsHTTP400Response")

        XCTAssertEqual("URLSession".snakeCase, "url_session")
        XCTAssertEqual("URLSession".camelCase, "URLSession")
        XCTAssertEqual("URLSession".pascalCase, "URLSession")

        XCTAssertEqual("HTTP".snakeCase, "http")
        XCTAssertEqual("HTTP".camelCase, "HTTP")
        XCTAssertEqual("HTTP".pascalCase, "HTTP")
    }
}
