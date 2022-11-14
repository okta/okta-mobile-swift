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
    
    public var errorDescription: String? { description }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Code.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case code = "error"
        case description = "errorDescription"
    }
}

extension OAuth2ServerError {
    ///  Possible  OAuth 2.0 server error code
    public enum Code: String, Decodable {
        /// The authorization request is still pending as the end user hasn't yet completed the user-interaction step
        case authorizationPending = "authorization_pending"
        /// the authorization request is still pending and polling should continue
        case slowDown = "slow_down"
        //The "device_code" has expired, and the device authorization session has concluded.
        case expiredToken = "expired_token"
        /// The server denied the request.
        case accessDenied = "access_denied"
        /// The specified client ID is invalid.
        case invalidClient = "invalid_client"
        /// The specified grant is invalid, expired, revoked, or doesn't match the redirect URI used in the authorization request.
        case invalidGrant = "invalid_grant"
        /// The request is missing a necessary parameter, the parameter has an invalid value, or the request contains duplicate parameters.
        case invalidRequest = "invalid_request"
        /// The scopes list contains an invalid or unsupported value.
        case invalidScope = "invalid_scope"
        /// The provided access token is invalid.
        case invalidToken = "invalid_token"
        /// The server encountered an internal error.
        case serverError = "server_error"
        /// The server is temporarily unavailable, but should be able to process the request at a later time.
        case temporarilyUnavailable = "temporarily_unavailable"
        /// The specified response type is invalid or unsupported.
        case unsupportedResponseType = "unsupported_response_type"
        /// The specified response mode is invalid or unsupported. This error is also thrown for disallowed response modes.
        case unsupportedResponseMode = "unsupported_response_mode"
    }
}
