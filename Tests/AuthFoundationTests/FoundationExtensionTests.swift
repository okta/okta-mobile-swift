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

import Testing

@testable import AuthFoundation

@Suite("Foundation Extensions")
struct FoundationExtensionTests {
    @Test("String case conversions")
    func stringCaseConversions() throws {
        #expect("clientId".snakeCase == "client_id")
        #expect("clientId".camelCase == "clientId")
        #expect("clientId".pascalCase == "ClientId")

        #expect("theValue".snakeCase == "the_value")
        #expect("theValue".camelCase == "theValue")
        #expect("theValue".pascalCase == "TheValue")

        #expect("Awesome".snakeCase == "awesome")
        #expect("Awesome".camelCase == "awesome")
        #expect("Awesome".pascalCase == "Awesome")

        #expect("version1Response".snakeCase == "version_1_response")
        #expect("version1Response".camelCase == "version1Response")
        #expect("version1Response".pascalCase == "Version1Response")

        #expect("Version1Response".snakeCase == "version_1_response")
        #expect("Version1Response".camelCase == "version1Response")
        #expect("Version1Response".pascalCase == "Version1Response")

        #expect("this_is_snake_case".snakeCase == "this_is_snake_case")
        #expect("this_is_snake_case".camelCase == "thisIsSnakeCase")
        #expect("this_is_snake_case".pascalCase == "ThisIsSnakeCase")

        #expect("__prefixedWithUnderscores".snakeCase == "__prefixed_with_underscores")
        #expect("__prefixedWithUnderscores".camelCase == "prefixedWithUnderscores")
        #expect("__prefixedWithUnderscores".pascalCase == "PrefixedWithUnderscores")

        #expect("isHTTPResponse".snakeCase == "is_http_response")
        #expect("isHTTPResponse".camelCase == "isHTTPResponse")
        #expect("isHTTPResponse".pascalCase == "IsHTTPResponse")

        #expect("is400HTTPResponse".snakeCase == "is_400_http_response")
        #expect("is400HTTPResponse".camelCase == "is400HTTPResponse")
        #expect("is400HTTPResponse".pascalCase == "Is400HTTPResponse")

        #expect("isHTTP400Response".snakeCase == "is_http_400_response")
        #expect("isHTTP400Response".camelCase == "isHTTP400Response")
        #expect("isHTTP400Response".pascalCase == "IsHTTP400Response")

        #expect("URLSession".snakeCase == "url_session")
        #expect("URLSession".camelCase == "URLSession")
        #expect("URLSession".pascalCase == "URLSession")

        #expect("HTTP".snakeCase == "http")
        #expect("HTTP".camelCase == "HTTP")
        #expect("HTTP".pascalCase == "HTTP")
    }
}
