//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Describes errors reported from an OAuth2 server.
public struct OAuth2ServerError: Decodable, Error, LocalizedError, Equatable {
    /// Error code.
    public let code: Code
    
    /// Error message, or description.
    public let description: String?
    
    /// Contains any additional values the server error reported alongside the code and description.
    public var additionalValues: [String: Any]
    
    public var errorDescription: String? { description }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Code.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        let additionalContainer = try decoder.container(keyedBy: AdditionalValuesCodingKeys.self)
        self.additionalValues = additionalContainer.decodeUnkeyedContainer(exclude: CodingKeys.self)
    }

    public init(code: String, description: String?, additionalValues: [String: Any]) {
        self.code = .init(rawValue: code) ?? .other(code: code)
        self.description = description
        self.additionalValues = additionalValues
    }
    
    public static func == (lhs: OAuth2ServerError, rhs: OAuth2ServerError) -> Bool {
        lhs.code == rhs.code &&
        lhs.description == rhs.description
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case code = "error"
        case description = "errorDescription"
    }
}

extension OAuth2ServerError {
    /// Possible  OAuth 2.0 server error code
    public enum Code: Decodable {
        /// The authorization request is still pending as the end user hasn't yet completed the user-interaction step
        case authorizationPending
        /// the authorization request is still pending and polling should continue
        case slowDown
        /// The `device_code` has expired, and the device authorization session has concluded.
        case expiredToken
        /// The server denied the request.
        case accessDenied
        /// The specified client ID is invalid.
        case invalidClient
        /// The specified grant is invalid, expired, revoked, or doesn't match the redirect URI used in the authorization request.
        case invalidGrant
        /// The request is missing a necessary parameter, the parameter has an invalid value, or the request contains duplicate parameters.
        case invalidRequest
        /// The scopes list contains an invalid or unsupported value.
        case invalidScope
        /// The provided access token is invalid.
        case invalidToken
        /// The server encountered an internal error.
        case serverError
        /// The server is temporarily unavailable, but should be able to process the request at a later time.
        case temporarilyUnavailable
        /// The specified response type is invalid or unsupported.
        case unsupportedResponseType
        /// The specified response mode is invalid or unsupported. This error is also thrown for disallowed response modes.
        case unsupportedResponseMode
        /// The client specified is not authorized to utilize the supplied grant type.
        case unauthorizedClient
        case directAuthAuthorizationPending
        case mfaRequired
        case invalidOTP
        case oobRejected
        case invalidChallengeTypesSupported
        /// An error code other than one of the standard ones defined above.
        case other(code: String)
    }
}

extension OAuth2ServerError.Code: RawRepresentable, Equatable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "authorization_pending":
            self = .authorizationPending
        case "slow_down":
            self = .slowDown
        case "expired_token":
            self = .expiredToken
        case "access_denied":
            self = .accessDenied
        case "invalid_client":
            self = .invalidClient
        case "invalid_grant":
            self = .invalidGrant
        case "invalid_request":
            self = .invalidRequest
        case "invalid_scope":
            self = .invalidScope
        case "invalid_token":
            self = .invalidToken
        case "server_error":
            self = .serverError
        case "temporarily_unavailable":
            self = .temporarilyUnavailable
        case "unsupported_response_type":
            self = .unsupportedResponseType
        case "unsupported_response_mode":
            self = .unsupportedResponseMode
        case "unauthorized_client":
            self = .unauthorizedClient
        case "direct_auth_authorization_pending":
            self = .directAuthAuthorizationPending
        case "mfa_required":
            self = .mfaRequired
        case "invalid_otp":
            self = .invalidOTP
        case "oob_rejected":
            self = .oobRejected
        case "invalid_challenge_types_supported":
            self = .invalidChallengeTypesSupported
        default:
            self = .other(code: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .authorizationPending:
            return "authorization_pending"
        case .slowDown:
            return "slow_down"
        case .expiredToken:
            return "expired_token"
        case .accessDenied:
            return "access_denied"
        case .invalidClient:
            return "invalid_client"
        case .invalidGrant:
            return "invalid_grant"
        case .invalidRequest:
            return "invalid_request"
        case .invalidScope:
            return "invalid_scope"
        case .invalidToken:
            return "invalid_token"
        case .serverError:
            return "server_error"
        case .temporarilyUnavailable:
            return "temporarily_unavailable"
        case .unsupportedResponseType:
            return "unsupported_response_type"
        case .unsupportedResponseMode:
            return "unsupported_response_mode"
        case .unauthorizedClient:
            return "unauthorized_client"
        case .directAuthAuthorizationPending:
            return "direct_auth_authorization_pending"
        case .mfaRequired:
            return "mfa_required"
        case .invalidOTP:
            return "invalid_otp"
        case .oobRejected:
            return "oob_rejected"
        case .invalidChallengeTypesSupported:
            return "invalid_challenge_types_supported"
        case .other(code: let code):
            return code
        }
    }
}
