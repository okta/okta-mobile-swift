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

#if canImport(UIKit) || canImport(AppKit)

extension WebAuthenticationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noCompatibleAuthenticationProviders:
            return NSLocalizedString("no_compatible_authentication_providers_description",
                                     bundle: .module,
                                     comment: "")
            
        case .cannotComposeAuthenticationURL:
            return NSLocalizedString("cannot_compose_authentication_url_description",
                                     bundle: .module,
                                     comment: "")
            
        case .authenticationProviderError(let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }

            return NSLocalizedString("authentication_provider_error",
                                  bundle: .module,
                                  comment: "")

        case .invalidRedirectScheme(let scheme):
            return String.localizedStringWithFormat(
                NSLocalizedString("invalid_redirect_scheme_description",
                                  bundle: .module,
                                  comment: ""),
                scheme ?? NSLocalizedString("no_scheme_defined",
                                            bundle: .module,
                                            comment: ""))

        case .userCancelledLogin:
            return NSLocalizedString("user_cancelled_login_description",
                                     bundle: .module,
                                     comment: "")
            
        case .missingIdToken:
            return NSLocalizedString("missing_id_token_description",
                                     bundle: .module,
                                     comment: "Missing ID Token")
            
        case .oauth2(error: let error):
            return error.localizedDescription

        case .generic(error: let error):
            if let error = error as? LocalizedError {
                return error.localizedDescription
            }
            let errorString = String(describing: error)

            return String.localizedStringWithFormat(
                NSLocalizedString("generic_description",
                                  bundle: .module,
                                  comment: ""),
                errorString)

        case .genericError(message: let message):
            return message
        }
    }
}

#endif
