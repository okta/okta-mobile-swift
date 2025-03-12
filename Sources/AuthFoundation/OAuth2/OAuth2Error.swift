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
    /// Could not create an invalid URL. This typically means the string passed to `URL` was malformed.
    case invalidUrl
    
    /// Cannot compose a URL to authenticate with.
    case cannotComposeUrl
    
    /// An OAuth2 server error has been returned.
    case server(error: OAuth2ServerError)

    /// A network error was encountered, encapsulating a ``APIClientError`` type describing the underlying error.
    case network(error: APIClientError)
    
    /// The given token type is missing.
    case missingToken(type: Token.Kind)
    
    /// Cannot perform an operation since the token is missing its client configuration.
    case missingClientConfiguration
    
    /// An operation was performed which requires a `redirect_uri`, but none was supplied to the client configuration.
    case missingRedirectUri
    
    /// Could not verify the token's signature.
    case signatureInvalid
    
    /// Missing location header for token redirect.
    case missingLocationHeader
    
    /// Missing the given required response key in the OAuth2 redirect.
    case missingOAuth2ResponseKey(_ name: String)
    
    /// The given OpenID configuration attribute is missing.
    case missingOpenIdConfiguration(attribute: String)
    
    /// The given nested error was thrown.
    case error(_ error: any Error)
    
    /// Cannot revoke the given token type.
    case cannotRevoke(type: Token.RevokeType)
    
    /// Multiple nested ``OAuth2Error`` errors were reported.
    case multiple(errors: [OAuth2Error])
}

extension OAuth2Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("invalid_url_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Invalid URL")

        case .missingRedirectUri:
            return NSLocalizedString("missing_client_redirect_uri",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Missing redirect URI")

        case .cannotComposeUrl:
            return NSLocalizedString("cannot_compose_url_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Cannot compose URL")

        case .server(error: let error):
            return error.errorDescription

        case .network(error: let error):
            return error.errorDescription

        case .missingToken(let type):
            return String.localizedStringWithFormat(
                NSLocalizedString("missing_token_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Missing token"),
                type.rawValue)

        case .missingClientConfiguration:
            return NSLocalizedString("missing_client_configuration_description",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Missing client configuration")

        case .signatureInvalid:
            return NSLocalizedString("signature_invalid",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Signature is invalid")

        case .missingLocationHeader:
            return NSLocalizedString("missing_location_header",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Missing redirect Location header for token exchange")

        case .missingOpenIdConfiguration(attribute: let name):
            return String.localizedStringWithFormat(
                NSLocalizedString("missing_openid_configuration_attribute",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Missing OpenID configuration attribute"),
                name)

        case .error(let error):
            if let error = error as? any LocalizedError {
                return error.localizedDescription
            }
            let errorString = String(describing: error)

            return String.localizedStringWithFormat(
                NSLocalizedString("error_description",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Localized error description"),
                errorString)

        case .cannotRevoke:
            return NSLocalizedString("cannot_revoke_token",
                                     tableName: "AuthFoundation",
                                     bundle: .authFoundation,
                                     comment: "Cannot revoke token")

        case .multiple(errors: let errors):
            let errorString = errors
                .map(\.localizedDescription)
                .joined(separator: ", ")
            
            return String.localizedStringWithFormat(
                NSLocalizedString("multiple_oauth2_errors",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Multiple OAuth2 errors"),
                errorString)
            
        case .missingOAuth2ResponseKey(let key):
            return String.localizedStringWithFormat(
                NSLocalizedString("missing_oauth2_response_key",
                                  tableName: "AuthFoundation",
                                  bundle: .authFoundation,
                                  comment: "Missing OAuth2 response key"),
                key)

        }
    }
}

extension OAuth2Error: Equatable {
    private static func compare(lhs: NSError, rhs: NSError) -> Bool {
        (lhs.code == rhs.code &&
         lhs.domain == rhs.domain)
    }
    
    public static func == (lhs: OAuth2Error, rhs: OAuth2Error) -> Bool {
        switch (lhs, rhs) {
        case (.invalidUrl, .invalidUrl): return true
        case (.missingRedirectUri, .missingRedirectUri): return true
        case (.cannotComposeUrl, .cannotComposeUrl): return true
        case (.signatureInvalid, .signatureInvalid): return true
        case (.missingLocationHeader, .missingLocationHeader): return true
        case (.missingClientConfiguration, .missingClientConfiguration): return true
        case (.server(error: let lhsError), .server(error: let rhsError)):
            return lhsError == rhsError

        case (.network(error: let lhsError), .network(error: let rhsError)):
            return lhsError == rhsError
            
        case (.missingToken(type: let lhsKind), .missingToken(type: let rhsKind)):
            return lhsKind == rhsKind
            
        case (.missingOpenIdConfiguration(attribute: let lhsAttribute), .missingOpenIdConfiguration(attribute: let rhsAttribute)):
            return lhsAttribute == rhsAttribute
            
        case (.error(let lhsError), .error(let rhsError)):
            return compare(lhs: lhsError as NSError, rhs: rhsError as NSError)

        case (.cannotRevoke(type: let lhsType), .cannotRevoke(type: let rhsType)):
            return lhsType == rhsType
            
        case (.multiple(errors: let lhsErrors), .multiple(errors: let rhsErrors)):
            return lhsErrors == rhsErrors
            
        default:
            return false
        }
    }
}
