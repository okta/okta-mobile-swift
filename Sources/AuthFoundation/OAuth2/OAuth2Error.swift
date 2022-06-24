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

/// Errors that may occur when interacting with OAuth2 endpoints.
public enum OAuth2Error: Error {
    case invalidUrl
    case cannotComposeUrl
    case oauth2Error(code: String, description: String?)
    case network(error: APIClientError)
    case missingToken(type: Token.Kind)
    case missingClientConfiguration
    case signatureInvalid
    case error(_ error: Error)
}

extension OAuth2Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("invalid_url_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")

        case .cannotComposeUrl:
            return NSLocalizedString("cannot_compose_url_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")

        case .oauth2Error(let code, let description):
            if let description = description {
                return String.localizedStringWithFormat(
                    NSLocalizedString("oauth2_error_description",
                                      tableName: "AuthFoundation",
                                      bundle: .authFoundation,
                                      comment: "Invalid URL"),
                    description, code)
            }
            
            return String.localizedStringWithFormat(
                NSLocalizedString("oauth2_error_code_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                code)

        case .network(let error):
            return error.localizedDescription

        case .missingToken(let type):
            return String.localizedStringWithFormat(
                NSLocalizedString("missing_token_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                type.rawValue)

        case .missingClientConfiguration:
            return NSLocalizedString("missing_client_configuration_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")

        case .signatureInvalid:
            return NSLocalizedString("signature_invalid",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")

        case .error(let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }
            let errorString = String(describing: error)

            return String.localizedStringWithFormat(
                NSLocalizedString("error_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                errorString)
        }
    }
}
