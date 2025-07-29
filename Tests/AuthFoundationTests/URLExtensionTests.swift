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

import Testing
import Foundation
@testable import TestCommon
@testable import AuthFoundation

@Suite("URL Extension Tests")
struct URLExtensionTests {
    @Test("Query Values with Custom Scheme")
    func testQueryValuesCustomScheme() throws {
        let redirectUri = try URL(requiredString: "com.example:/callback")
        var uri: URL
        var error: OAuth2Error?

        uri = try URL(requiredString: "urn:foo:bar")
        #expect(try uri.queryValues() == [:])
        error = #expect(throws: OAuth2Error.self) {
            try uri.queryValues(matching: redirectUri)
        }
        #expect(error == .redirectUri(uri, reason: .scheme("urn")))

        uri = try URL(requiredString: "COM.EXAMPLE:/")
        #expect(try uri.queryValues() == [:])
        error = #expect(throws: OAuth2Error.self) {
            try uri.queryValues(matching: redirectUri)
        }
        #expect(error == .redirectUri(uri, reason: .hostOrPath))

        uri = try URL(requiredString: "com.example:/callback?foo=bar&error_description=this+is+the+error")
        #expect(try uri.queryValues() == ["foo": "bar", "error_description": "this is the error"])
        #expect(try uri.queryValues(matching: redirectUri) == ["foo": "bar", "error_description": "this is the error"])
    }

    @Test("Query Values with HTTP Scheme")
    func testQueryValuesHTTPScheme() throws {
        let redirectUri = try URL(requiredString: "https://example.com/callback")
        var uri: URL
        var error: OAuth2Error?
        
        uri = try URL(requiredString: "com.example:/callback")
        error = #expect(throws: OAuth2Error.self) {
            try uri.queryValues(matching: redirectUri)
        }
        
        #expect(error == .redirectUri(uri, reason: .scheme("com.example")))

        uri = try URL(requiredString: "https://www.example.com/callback")
        #expect(try uri.queryValues() == [:])
        error = #expect(throws: OAuth2Error.self) {
            try uri.queryValues(matching: redirectUri)
        }
        #expect(error == .redirectUri(uri, reason: .hostOrPath))

        uri = try URL(requiredString: "https://example.com/callback?foo=bar&error_description=this+is+the+error")
        #expect(try uri.queryValues() == ["foo": "bar", "error_description": "this is the error"])
        #expect(try uri.queryValues(matching: redirectUri) == ["foo": "bar", "error_description": "this is the error"])
    }

    @Test("Redirect URI Variations")
    func testRedirectUriVariations() throws {
        let nilHost = try URL(requiredString: "com.test:///login")
        #expect(try nilHost.queryValues(matching: nilHost) == [:])
    }
}
