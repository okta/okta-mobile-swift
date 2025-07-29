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

@testable import AuthFoundation

struct MockJWKValidatorTrait: TestTrait, SuiteTrait, TestScoping {
    let validator: MockJWKValidator = .init()
    
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await JWK.$providers.withValue(.init(validator: validator)) {
            try await function()
        }
    }
}

extension Trait where Self == MockJWKValidatorTrait {
    static var mockJWKValidator: Self { Self() }
}
