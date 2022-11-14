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

/// Errors that may occur at the API or network level.
public enum APIClientError: Error {
    case invalidUrl
    case missingResponse
    case invalidResponse
    case cannotParseResponse(error: Error)
    case invalidRequestData
    case missingRefreshSettings
    case unsupportedContentType(_ type: APIContentType)
    case serverError(_ error: Error)
    case statusCode(_ statusCode: Int)
    case validation(error: Error)
    case unknown
}

extension APIClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("invalid_url_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
            
        case .missingResponse:
            return NSLocalizedString("missing_response_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
            
        case .invalidResponse:
            return NSLocalizedString("invalid_response_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
            
        case .cannotParseResponse(error: let error):
            let errorString: String
            if let error = error as? LocalizedError {
                errorString = error.localizedDescription
            } else {
                errorString = String(describing: error)
            }

            return String.localizedStringWithFormat(
                NSLocalizedString("cannot_parse_response_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                errorString)
            
        case .invalidRequestData:
            return NSLocalizedString("invalid_request_data_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
            
        case .missingRefreshSettings:
            return NSLocalizedString("missing_refresh_settings_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
            
        case .unsupportedContentType(let type):
            return String.localizedStringWithFormat(
                NSLocalizedString("unsupported_content_type_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                type.rawValue)
            
        case .serverError(let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }
            let errorString = String(describing: error)

            return String.localizedStringWithFormat(
                NSLocalizedString("server_error_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                errorString)
            
        case .statusCode(let code):
            return String.localizedStringWithFormat(
                NSLocalizedString("status_code_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Invalid URL"),
                code)

        case .validation(error: let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }

            return NSLocalizedString("validation_error",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
        case .unknown:
            return NSLocalizedString("unknown_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")
        }
    }
}

extension APIClientError: Equatable {
    private static func compare(lhs: NSError, rhs: NSError) -> Bool {
        (lhs.code == rhs.code &&
         lhs.domain == rhs.domain)
    }
    
    public static func == (lhs: APIClientError, rhs: APIClientError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidUrl, .invalidUrl): return true
        case (.missingResponse, .missingResponse): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.invalidRequestData, .invalidRequestData): return true
        case (.missingRefreshSettings, .missingRefreshSettings): return true
        case (.unknown, .unknown): return true
            
        case (.unsupportedContentType(let lhsType), .unsupportedContentType(let rhsType)):
            return lhsType == rhsType
            
        case (.statusCode(let lhsStatusCode), .statusCode(let rhsStatusCode)):
            return lhsStatusCode == rhsStatusCode
            
        case (.cannotParseResponse(error: let lhsError), .cannotParseResponse(error: let rhsError)):
            return compare(lhs: lhsError as NSError, rhs: rhsError as NSError)
            
        case (.serverError(let lhsError), .serverError(let rhsError)):
            return compare(lhs: lhsError as NSError, rhs: rhsError as NSError)

        case (.validation(error: let lhsError), .validation(error: let rhsError)):
            return compare(lhs: lhsError as NSError, rhs: rhsError as NSError)
            
        default:
            return false
        }
    }
}
