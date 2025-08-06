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

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
extension BrowserSigninError: LocalizedError {
    init(_ error: any Error) {
        let nsError = error as NSError
        #if canImport(AuthenticationServices)
        if nsError.domain == ASWebAuthenticationSessionErrorDomain,
           nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
        {
            self = .userCancelledLogin
            return
        }
        #endif
        
        if let error = error as? OAuth2Error {
            self = .oauth2(error: error)
        } else if let error = error as? OAuth2ServerError {
            self = .serverError(error)
        } else {
            self = .generic(error: error)
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .noCompatibleAuthenticationProviders:
            return NSLocalizedString("no_compatible_authentication_providers_description",
                                     tableName: "BrowserSignin",
                                     bundle: .browserSignin,
                                     comment: "")
            
        case .cannotComposeAuthenticationURL:
            return NSLocalizedString("cannot_compose_authentication_url_description",
                                     tableName: "BrowserSignin",
                                     bundle: .browserSignin,
                                     comment: "")
            
        case .authenticationProvider(error: let error):
            if let error = error as? (any LocalizedError) {
                return error.localizedDescription
            }
            
            return NSLocalizedString("authentication_provider_error",
                                     tableName: "BrowserSignin",
                                     bundle: .browserSignin,
                                     comment: "")
            
        case .invalidRedirectScheme(let scheme):
            return String.localizedStringWithFormat(
                NSLocalizedString("invalid_redirect_scheme_description",
                                  tableName: "BrowserSignin",
                                  bundle: .browserSignin,
                                  comment: ""),
                scheme ?? NSLocalizedString("no_scheme_defined",
                                            tableName: "BrowserSignin",
                                            bundle: .browserSignin,
                                            comment: ""))
            
        case .userCancelledLogin:
            return NSLocalizedString("user_cancelled_login_description",
                                     tableName: "BrowserSignin",
                                     bundle: .browserSignin,
                                     comment: "")
            
        case .missingIdToken:
            return NSLocalizedString("missing_id_token_description",
                                     tableName: "BrowserSignin",
                                     bundle: .browserSignin,
                                     comment: "Missing ID Token")
            
        case .oauth2(error: let error):
            return error.localizedDescription
            
        case .serverError(let error):
            return error.errorDescription
            
        case .generic(error: let error):
            if let error = error as? (any LocalizedError) {
                return error.localizedDescription
            }
            let errorString = String(describing: error)
            
            return String.localizedStringWithFormat(
                NSLocalizedString("generic_description",
                                  tableName: "BrowserSignin",
                                  bundle: .browserSignin,
                                  comment: ""),
                errorString)

        case .noAuthenticatorProviderResonse:
            return NSLocalizedString("no_authenticator_provider_response",
                                     tableName: "BrowserSignin",
                                     bundle: .browserSignin,
                                     comment: "No authenticator provider response")
        case .genericError(message: let message):
            return message
        case .noSignOutFlowProvided:
            return "FOO"
        case .cannotStartBrowserSession:
            return "FOO"
        }
    }
}

extension BrowserSigninError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.noCompatibleAuthenticationProviders, .noCompatibleAuthenticationProviders): return true
        case (.noSignOutFlowProvided, .noSignOutFlowProvided): return true
        case (.cannotStartBrowserSession, .cannotStartBrowserSession): return true
        case (.cannotComposeAuthenticationURL, .cannotComposeAuthenticationURL): return true
        case (.userCancelledLogin, .userCancelledLogin): return true
        case (.noAuthenticatorProviderResonse, .noAuthenticatorProviderResonse): return true
        case (.missingIdToken, .missingIdToken): return true
        case (.authenticationProvider(error: let lhsValue), .authenticationProvider(error: let rhsValue)):
            return lhsValue as NSError == rhsValue as NSError
        case (.serverError(let lhsValue), .serverError(let rhsValue)):
            return lhsValue == rhsValue
        case (.invalidRedirectScheme(let lhsValue), .invalidRedirectScheme(let rhsValue)):
            return lhsValue == rhsValue
        case (.oauth2(error: let lhsValue), .oauth2(error: let rhsValue)):
            return lhsValue == rhsValue
        case (.generic(error: let lhsValue), .generic(error: let rhsValue)):
            return lhsValue as NSError == rhsValue as NSError
        case (.genericError(message: let lhsValue), .genericError(message: let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}
