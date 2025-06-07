//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OAuth2Auth

final class URLExtensionTests: XCTestCase {
    func testAuthorizationCodeFromURL() throws {
        let redirectUri = try XCTUnwrap(try URL(requiredString: "com.example:/callback"))
        let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                       clientId: "clientid",
                                                       scope: "openid",
                                                       redirectUri: redirectUri)
        var uri: URL

        uri = try XCTUnwrap(try URL(requiredString: "urn:foo:bar"))
        XCTAssertThrowsError(try uri.authorizationCode(state: "ABCD123",
                                                       configuration: configuration))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .scheme("urn")))
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/"))
        XCTAssertThrowsError(try uri.authorizationCode(state: "ABCD123",
                                                       configuration: configuration))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .hostOrPath))
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback"))
        XCTAssertThrowsError(try uri.authorizationCode(state: "ABCD123",
                                                       configuration: configuration))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .state(nil)))
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback?state=abcd"))
        XCTAssertThrowsError(try uri.authorizationCode(state: "ABCD123",
                                                       configuration: configuration))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .state("abcd")))
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback?state=ABCD123"))
        XCTAssertThrowsError(try uri.authorizationCode(state: "ABCD123",
                                                       configuration: configuration))
        { error in
            XCTAssertEqual(error as? OAuth2Error, .redirectUri(uri, reason: .codeRequired))
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback?error=some_error&error_description=some+error+message"))
        XCTAssertThrowsError(try uri.authorizationCode(state: "ABCD123",
                                                       configuration: configuration))
        { error in
            let serverError = error as? OAuth2ServerError
            XCTAssertEqual(serverError?.code, .other(code: "some_error"))
            XCTAssertEqual(serverError?.description, "some error message")
        }

        uri = try XCTUnwrap(try URL(requiredString: "com.example:/callback?state=ABCD123&code=foo"))
        XCTAssertEqual(try uri.authorizationCode(state: "ABCD123",
                                                 configuration: configuration),
                       "foo")
    }

    func testAuthorizationCodeFromHTTPSURL() throws {
        let redirectUri = try XCTUnwrap(try URL(requiredString: "https://example.com/callback"))
        let configuration = OAuth2Client.Configuration(issuerURL: URL(string: "https://example.com")!,
                                                       clientId: "clientid",
                                                       scope: "openid",
                                                       redirectUri: redirectUri)
        var uri: URL

        uri = try XCTUnwrap(try URL(requiredString: "https://example.com/callback?state=ABCD123&code=foo"))
        XCTAssertEqual(try uri.authorizationCode(state: "ABCD123",
                                                 configuration: configuration),
                       "foo")
    }
}
