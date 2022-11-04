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

import XCTest

@testable import TestCommon
@testable import AuthFoundation

#if canImport(LocalAuthentication) && !os(tvOS)
import LocalAuthentication

final class CredentialSecurityTests: XCTestCase {
    func testContextExtension() throws {
        XCTAssertNil([Credential.Security]().context)
        
        let context = LAContext()
        XCTAssertEqual([Credential.Security.context(context)].context,
                       context)
    }
    
    func testAccessibilityExtension() throws {
        XCTAssertNil([Credential.Security]().accessibility)
        XCTAssertEqual([Credential.Security.accessibility(.afterFirstUnlock)].accessibility,
                       .afterFirstUnlock)
        XCTAssertEqual([Credential.Security.accessibility(.afterFirstUnlock),
                        Credential.Security.accessibility(.unlocked)].accessibility,
                       .afterFirstUnlock)
    }

    func testAccessGroupExtension() throws {
        XCTAssertNil([Credential.Security]().accessGroup)
        XCTAssertEqual([Credential.Security.accessGroup("Foo")].accessGroup,
                       "Foo")
        XCTAssertEqual([Credential.Security.accessGroup("Foo"),
                        Credential.Security.accessGroup("Bar")].accessGroup,
                       "Foo")
    }

    func testAccessControlFlagsExtension() throws {
        XCTAssertNil([Credential.Security]().accessControlFlags)
        XCTAssertEqual([Credential.Security.accessControl(.devicePasscode)].accessControlFlags,
                       .devicePasscode)
    }

    func testCreateAccessControlExtension() throws {
        XCTAssertNil(try [Credential.Security]().createAccessControl(accessibility: .unlocked))

        XCTAssertNotNil(try [Credential.Security.accessControl(.devicePasscode)].createAccessControl(accessibility: .unlocked))
        
        let options: [Credential.Security] = [
            .accessControl([.devicePasscode, .userPresence])
        ]
        XCTAssertThrowsError(try options.createAccessControl(accessibility: .unlocked))
    }
}
#endif
