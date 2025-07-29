//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@testable import TestCommon
@testable import AuthFoundation

#if canImport(LocalAuthentication) && !os(tvOS)
import LocalAuthentication

@Suite("Credential security tests")
struct CredentialSecurityTests {
    @Test("Context extension")
    func testContextExtension() throws {
        #expect([Credential.Security]().context == nil)
        
        let context = LAContext()
        #expect([Credential.Security.context(context)].context == context)
    }
    
    @Test("Accessibility extension")
    func testAccessibilityExtension() throws {
        #expect([Credential.Security]().accessibility == nil)
        #expect([Credential.Security.accessibility(.afterFirstUnlock)].accessibility == .afterFirstUnlock)
        #expect([Credential.Security.accessibility(.afterFirstUnlock),
                 Credential.Security.accessibility(.unlocked)].accessibility == .afterFirstUnlock)
    }

    @Test("Access group extension")
    func testAccessGroupExtension() throws {
        #expect([Credential.Security]().accessGroup == nil)
        #expect([Credential.Security.accessGroup("Foo")].accessGroup == "Foo")
        #expect([Credential.Security.accessGroup("Foo"),
                 Credential.Security.accessGroup("Bar")].accessGroup == "Foo")
    }

    @Test("Access control flags extension")
    func testAccessControlFlagsExtension() throws {
        #expect([Credential.Security]().accessControlFlags == nil)
        #expect([Credential.Security.accessControl(.devicePasscode)].accessControlFlags == .devicePasscode)
    }

    @Test("Create access control extension")
    func testCreateAccessControlExtension() throws {
        #expect(try [Credential.Security]().createAccessControl(accessibility: .unlocked) == nil)

        #expect(try [Credential.Security.accessControl(.devicePasscode)].createAccessControl(accessibility: .unlocked) != nil)
        
        let options: [Credential.Security] = [
            .accessControl([.devicePasscode, .userPresence])
        ]
        #expect(throws: (any Error).self) {
            try options.createAccessControl(accessibility: .unlocked)
        }
    }
}
#endif
