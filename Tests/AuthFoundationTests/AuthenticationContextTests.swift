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

import Foundation
import Testing
@testable import AuthFoundation

@Suite("Authentication context tests", .disabled("Debugging test deadlocks within CI"))
struct AuthenticationContextTests {
    @Test("Standard context functionality")
    func testStandardContext() throws {
        var context = StandardAuthenticationContext()
        #expect(context.acrValues == nil)
        #expect(context.additionalParameters == nil)
        #expect(context.persistValues == nil)
        for category in OAuth2APIRequestCategory.allCases {
            #expect(context.parameters(for: category) == nil)
        }
        
        context.acrValues = ["urn:foo:bar", "urn:ietf:foo:bar"]
        #expect(context.persistValues == [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar"
        ])
        #expect(context.parameters(for: .authorization)?.mapValues(\.stringValue) == [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar"
        ])

        context = .init(additionalParameters: [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar",
            "prompt": "none",
        ])
        #expect(context.acrValues == [
            "urn:foo:bar",
            "urn:ietf:foo:bar",
        ])
        #expect(context.additionalParameters?.mapValues(\.stringValue) == [
            "prompt": "none"
        ])
        #expect(context.persistValues == [
            "acr_values": "urn:foo:bar urn:ietf:foo:bar",
        ])
        #expect(context.parameters(for: .authorization)?.mapValues(\.stringValue) == [
            "prompt": "none",
            "acr_values": "urn:foo:bar urn:ietf:foo:bar",
        ])
        
        for category in OAuth2APIRequestCategory.allCases {
            let parameters = context.parameters(for: category)
            #expect(parameters?["prompt"]?.stringValue == "none")

            if category == .authorization {
                #expect(parameters?["acr_values"]?.stringValue == "urn:foo:bar urn:ietf:foo:bar")
            }
        }
        
        context = .init(additionalParameters: ["acr_values": "foo"])
        #expect(context.acrValues == ["foo"])
        #expect(context.additionalParameters == nil)

        context = .init()
        #expect(context.acrValues == nil)
        #expect(context.additionalParameters == nil)
    }
}
