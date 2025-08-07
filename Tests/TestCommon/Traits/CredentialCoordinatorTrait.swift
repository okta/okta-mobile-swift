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

struct CredentialCoordinatorTrait: TestTrait, SuiteTrait, TestScoping {
    enum Style: Sendable {
        case mockEverything
        case userDefaultStorage
        case defaultDataSource
    }
    
    var isRecursive: Bool { true }
    
    let style: Style
    init(style: Style = .mockEverything) {
        self.style = style
    }
    
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await Credential.$providers.withValue(.init(
            defaultCredentialDataSource: {
                switch style {
                case .mockEverything, .userDefaultStorage:
                    MockCredentialDataSource()
                case .defaultDataSource:
                    DefaultCredentialDataSource()
                }
            },
            defaultTokenStorage: {
                switch style {
                case .mockEverything, .defaultDataSource:
                    return MockTokenStorage()

                case .userDefaultStorage:
                    let userDefaults = UserDefaults(suiteName: test.id.description)!
                    userDefaults.removePersistentDomain(forName: test.id.description)
                    
                    return UserDefaultsTokenStorage(userDefaults: userDefaults)
                }
            }))
        {
            try await function()
            
            if case .userDefaultStorage = style,
               let userDefaults = UserDefaults(suiteName: test.id.description)
            {
                userDefaults.removePersistentDomain(forName: test.id.description)
            }
        }
    }
}

extension Trait where Self == CredentialCoordinatorTrait {
    static var credentialCoordinator: Self {
        CredentialCoordinatorTrait()
    }
    
    static func credentialCoordinator(style: CredentialCoordinatorTrait.Style) -> Self {
        CredentialCoordinatorTrait(style: style)
    }
}
