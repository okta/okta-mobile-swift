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
                                  bundle: .module,
                                  comment: ""),
                status)

        case .cannotList(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_list",
                                  bundle: .module,
                                  comment: ""),
                status)

        case .cannotSave(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_save",
                                  bundle: .module,
                                  comment: ""),
                status)

        case .cannotUpdate(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_update",
                                  bundle: .module,
                                  comment: ""),
                status)

        case .cannotDelete(code: let status):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_cannot_delete",
                                  bundle: .module,
                                  comment: ""),
                status)

        case .accessControlInvalid(code: let code, description: let description):
            return String.localizedStringWithFormat(
                NSLocalizedString("keychain_access_control_invalid",
                                  bundle: .module,
                                  comment: ""),
                description ?? "", code)
            
        case .notFound:
            return NSLocalizedString("keychain_not_found",
                                     bundle: .module,
                                     comment: "")

        case .invalidFormat:
            return NSLocalizedString("keychain_invalid_format",
                                     bundle: .module,
                                     comment: "")

        case .invalidAccessibilityOption:
            return NSLocalizedString("keychain_invalid_accessibility_option",
                                     bundle: .module,
                                     comment: "")

        case .missingAccount:
            return NSLocalizedString("keychain_missing_account",
                                     bundle: .module,
                                     comment: "")

        case .missingValueData:
            return NSLocalizedString("keychain_missing_value_data",
                                     bundle: .module,
                                     comment: "")

        case .missingAttribute:
            return NSLocalizedString("keychain_missing_attribute",
                                     bundle: .module,
                                     comment: "")
        }
    }
}

#endif
