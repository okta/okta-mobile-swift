//
// Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import TestCommon
@testable import AuthFoundation

final class URLExtensionTests: XCTestCase {
    func testQueryValuesCustomScheme() throws {
        let redirectUri = try XCTUnwrap(try URL(requiredString: "com.example:/callback"))
        var uri: URL

        uri = try XCTUnwrap(try URL(requiredString: "urn:foo:bar"))
        XCTAssertEqual(try uri.queryValues(), [:])
        XCTAssertThrowsError(try uri.queryValues(matching: redirectUri))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .scheme("urn")))
        }

        uri = try XCTUnwrap(try URL(requiredString: "COM.EXAMPLE:/"))
        XCTAssertEqual(try uri.queryValues(), [:])
        XCTAssertThrowsError(try uri.queryValues(matching: redirectUri))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .hostOrPath))
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback?foo=bar&error_description=this+is+the+error"))
        XCTAssertEqual(try uri.queryValues(), ["foo": "bar", "error_description": "this is the error"])
        XCTAssertEqual(try uri.queryValues(matching: redirectUri), ["foo": "bar", "error_description": "this is the error"])
    }

    func testQueryValuesHTTPScheme() throws {
        let redirectUri = try XCTUnwrap(try URL(requiredString: "https://example.com/callback"))
        var uri: URL

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback"))
        XCTAssertThrowsError(try uri.queryValues(matching: redirectUri))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .scheme("com.example")))
        }

        uri = try XCTUnwrap(try URL(requiredString: "https://www.example.com/callback"))
        XCTAssertEqual(try uri.queryValues(), [:])
        XCTAssertThrowsError(try uri.queryValues(matching: redirectUri))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .hostOrPath))
        }

        uri = try XCTUnwrap(try URL(requiredString: "https://example.com/callback?foo=bar&error_description=this+is+the+error"))
        XCTAssertEqual(try uri.queryValues(), ["foo": "bar", "error_description": "this is the error"])
        XCTAssertEqual(try uri.queryValues(matching: redirectUri), ["foo": "bar", "error_description": "this is the error"])
    }

    func testRedirectUriVariations() throws {
        let nilHost = try XCTUnwrap(try URL(requiredString: "com.test:///login"))
        XCTAssertNoThrow(try nilHost.queryValues(matching: nilHost))
    }
}
