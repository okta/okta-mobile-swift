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

extension AuthorizationCodeFlow.RedirectError {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.invalidRedirectUrl, .invalidRedirectUrl): return true
        case (.missingQueryArguments, .missingQueryArguments): return true
        case (.missingAuthorizationCode, .missingAuthorizationCode): return true
            
        case (.unexpectedScheme(let lhsValue), .unexpectedScheme(let rhsValue)):
            return lhsValue == rhsValue
            
        case (.invalidState(let lhsValue), .invalidState(let rhsValue)):
            return lhsValue == rhsValue
            
        default:
            return false
        }
    }
}
    
extension AuthenticationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .flowNotReady:
            return NSLocalizedString("flow_not_ready_description",
                                     tableName: "OktaOAuth2",
                                     bundle: .oktaOAuth2,
                                     comment: "Invalid URL")
        }
    }
}

extension AuthorizationCodeFlow.RedirectError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidRedirectUrl:
            return NSLocalizedString("invalid_redirect_url_description",
                                     tableName: "OktaOAuth2",
                                     bundle: .oktaOAuth2,
                                     comment: "Invalid URL")

        case .unexpectedScheme:
            return NSLocalizedString("unexpected_scheme_description",
                                     tableName: "OktaOAuth2",
                                     bundle: .oktaOAuth2,
                                     comment: "Invalid URL")

        case .missingQueryArguments:
            return NSLocalizedString("missing_query_arguments_description",
                                     tableName: "OktaOAuth2",
                                     bundle: .oktaOAuth2,
                                     comment: "Invalid URL")
        
        case .invalidState:
            return NSLocalizedString("invalid_state_description",
                                     tableName: "OktaOAuth2",
                                     bundle: .oktaOAuth2,
                                     comment: "Invalid URL")
            
        case .missingAuthorizationCode:
            return NSLocalizedString("missing_authorization_code_description",
                                     tableName: "OktaOAuth2",
                                     bundle: .oktaOAuth2,
                                     comment: "Invalid URL")
        }
    }
}
