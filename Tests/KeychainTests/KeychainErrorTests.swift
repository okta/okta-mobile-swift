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
@testable import Keychain

final class KeychainErrorTests: XCTestCase {
    func testKeychainError() {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
        XCTAssertNotEqual(KeychainError.cannotGet(code: noErr).errorDescription,
                          "keychain_cannot_get")
        XCTAssertNotEqual(KeychainError.cannotList(code: noErr).errorDescription,
                          "keychain_cannot_list")
        XCTAssertNotEqual(KeychainError.cannotSave(code: noErr).errorDescription,
                          "keychain_cannot_save")
        XCTAssertNotEqual(KeychainError.cannotUpdate(code: noErr).errorDescription,
                          "keychain_cannot_update")
        XCTAssertNotEqual(KeychainError.cannotDelete(code: noErr).errorDescription,
                          "keychain_cannot_delete")
        XCTAssertNotEqual(KeychainError.accessControlInvalid(code: 0, description: "error").errorDescription,
                          "keychain_access_control_invalid")
        XCTAssertNotEqual(KeychainError.notFound.errorDescription,
                          "keychain_not_found")
        XCTAssertNotEqual(KeychainError.invalidFormat.errorDescription,
                          "keychain_invalid_format")
        XCTAssertNotEqual(KeychainError.invalidAccessibilityOption.errorDescription,
                          "keychain_invalid_accessibility_option")
        XCTAssertNotEqual(KeychainError.missingAccount.errorDescription,
                          "keychain_missing_account")
        XCTAssertNotEqual(KeychainError.missingValueData.errorDescription,
                          "keychain_missing_value_data")
        XCTAssertNotEqual(KeychainError.missingAttribute.errorDescription,
                          "keychain_missing_attribute")
        #else
        XCTSkip()
        #endif
    }
}
