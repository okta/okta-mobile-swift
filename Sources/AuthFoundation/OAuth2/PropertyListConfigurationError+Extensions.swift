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

extension OAuth2Client.PropertyListConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .defaultPropertyListNotFound:
            return NSLocalizedString("default_property_list_not_found_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
            
        case .invalidPropertyList(url: let url):
            return String.localizedStringWithFormat(
                NSLocalizedString("invalid_property_list_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                url.lastPathComponent)

        case .cannotParsePropertyList(let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }
            
            let errorString: String
            if let error = error {
                errorString = String(describing: error)
            } else {
                errorString = NSLocalizedString("unknown_error_message",
                                                tableName: "AuthFoundation",
                                                bundle: .authFoundation,
                                                comment: "")
            }

            return String.localizedStringWithFormat(
                NSLocalizedString("generic_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                errorString)

        case .missingConfigurationValues:
            return NSLocalizedString("missing_configuration_values_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "")
        case .invalidConfiguration(name: let name, value: let value):
            return String.localizedStringWithFormat(
                NSLocalizedString("invalid_configuration",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: ""),
                name, value ?? "")
        }
    }
}
