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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)

/// Describes errors that may occur when interacting with the keychain.
public enum KeychainError: Error {
    case cannotGet(code: OSStatus)
    case cannotList(code: OSStatus)
    case cannotSave(code: OSStatus)
    case cannotDelete(code: OSStatus)
    case cannotUpdate(code: OSStatus)
    case accessControlInvalid(code: OSStatus, description: String?)
    case notFound
    case invalidFormat
    case invalidAccessibilityOption
    case missingAccount
    case missingValueData
    case missingAttribute
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cannotGet(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_get",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                status)

        case .cannotList(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_list",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                status)

        case .cannotSave(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_save",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                status)

        case .cannotUpdate(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_update",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                status)

        case .cannotDelete(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_delete",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                status)

        case .accessControlInvalid(code: let code, description: let description):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_access_control_invalid",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                description ?? "", code)
            
        case .notFound:
            return NSLocalizedString("keychain_not_found",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidFormat:
            return NSLocalizedString("keychain_invalid_format",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .invalidAccessibilityOption:
            return NSLocalizedString("keychain_invalid_accessibility_option",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .missingAccount:
            return NSLocalizedString("keychain_missing_account",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .missingValueData:
            return NSLocalizedString("keychain_missing_value_data",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")

        case .missingAttribute:
            return NSLocalizedString("keychain_missing_attribute",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        }
    }
}

#endif
