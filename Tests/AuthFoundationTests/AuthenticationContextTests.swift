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

final class AuthenticationContextTests: XCTestCase {
    func testStandardContext() throws {
        var context = StandardAuthenticationContext()
        XCTAssertNil(context.acrValues)
        XCTAssertNil(context.additionalParameters)
        XCTAssertNil(context.persistValues)
        for category in OAuth2APIRequestCategory.allCases {
            XCTAssertNil(context.parameters(for: category))
        }
        
        context.acrValues = ["urn:foo:bar", "urn:ietf:foo:bar"]
        XCTAssertEqual(context.persistValues, [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar"
        ])
        XCTAssertEqual(context.parameters(for: .authorization)?.mapValues(\.stringValue), [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar"
        ])

        context = .init(additionalParameters: [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar",
            "prompt": "none",
        ])
        XCTAssertEqual(context.acrValues, [
            "urn:foo:bar",
            "urn:ietf:foo:bar",
        ])
        XCTAssertEqual(context.additionalParameters?.mapValues(\.stringValue), [
            "prompt": "none"
        ])
        XCTAssertEqual(context.persistValues, [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar",
        ])
        XCTAssertEqual(context.parameters(for: .authorization)?.mapValues(\.stringValue), [
            "prompt": "none",
            "acr_values": "urn:foo:bar urn:ietf:foo:bar",
        ])
        
        for category in OAuth2APIRequestCategory.allCases {
            let parameters = context.parameters(for: category)
            XCTAssertEqual(parameters?["prompt"]?.stringValue, "none")

            if category == .authorization {
                XCTAssertEqual(parameters?["acr_values"]?.stringValue, "urn:foo:bar urn:ietf:foo:bar")
            }
        }
        
        context = .init(additionalParameters: ["acr_values": "foo"])
        XCTAssertEqual(context.acrValues, ["foo"])
        XCTAssertNil(context.additionalParameters)

        context = .init()
        XCTAssertNil(context.acrValues)
        XCTAssertNil(context.additionalParameters)
    }
}
