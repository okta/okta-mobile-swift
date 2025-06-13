//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension AuthorizationCodeFlow {
    /// A model representing the context and current state for an authorization session.
    public struct Context: Sendable, AuthenticationContext, IDTokenValidatorContext {
        /// The `PKCE` credentials to use in the authorization request.
        ///
        /// This value may be `nil` on platforms that do not support PKCE.
        public let pkce: PKCE?
        
        /// The "nonce" value to send with this authorization request.
        public let nonce: String?

        /// The maximum age an ID token can be when authenticating.
        public var maxAge: TimeInterval? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// The ACR values, if any, which should be requested by the client.
        @ClaimCollection
        public var acrValues: [String]? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// The state string to use when creating an authentication URL.
        public var state: String {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// The username to pre-populate if prompting for authentication.
        public var loginHint: String? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// Value passed to the Social IdP when performing social login.
        public var display: String? {
            didSet {
                authenticationURL = nil
            }
        }
        
        public var idTokenHint: String? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// Control how the user is prompted when authentication starts.
        ///
        /// > Note: The default behavior is ``Prompt/none``.
        public var prompt: Prompt? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// Optional preferred languages and scripts for the user interface.
        public var uiLocales: [String]? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// Optional preferred languages and scripts for Claims being returned.
        public var claimsLocales: [String]? {
            didSet {
                authenticationURL = nil
            }
        }
        
        /// Any additional query string parameters you would like to supply to the authorization server.
        public var additionalParameters: [String: any APIRequestArgument]? {
            didSet {
                authenticationURL = nil
            }
        }

        /// The current authentication URL, or `nil` if one has not yet been generated.
        public internal(set) var authenticationURL: URL?
        
        /// Initializer for creating a context with a custom state string.
        /// - Parameters:
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        ///   - maxAge: The maximum age an ID token can be when authenticating.
        public init(state: String? = nil,
                    maxAge: TimeInterval? = nil,
                    acrValues: ClaimCollection<[String]?> = nil,
                    additionalParameters: [String: any APIRequestArgument]? = nil)
        {
            let nonce = additionalParameters?["nonce"] as? String ?? .nonce()
            let state = state ?? additionalParameters?["state"] as? String ?? UUID().uuidString
            let maxAge = maxAge ?? additionalParameters?.maxAge
            self.init(pkce: PKCE(),
                      nonce: nonce,
                      maxAge: maxAge,
                      acrValues: acrValues,
                      state: state,
                      additionalParameters: additionalParameters?.omitting("nonce", "max_age", "state"))
        }

        init(pkce: PKCE?,
             nonce: String,
             maxAge: TimeInterval?,
             acrValues: ClaimCollection<[String]?> = nil,
             state: String,
             additionalParameters: [String: any APIRequestArgument]?)
        {
            self.pkce = pkce
            self.nonce = nonce
            self.state = state
            self.maxAge = maxAge
            self._acrValues = acrValues
            
            var remainingParameters = additionalParameters
            self.idTokenHint = remainingParameters?.removeValue(forKey: "id_token_hint") as? String
            self.loginHint = remainingParameters?.removeValue(forKey: "login_hint") as? String
            self.display = remainingParameters?.removeValue(forKey: "display") as? String
            self.uiLocales = remainingParameters?.removeSpaceSeparatedValues(forKey: "ui_locales")
            self.claimsLocales = remainingParameters?.removeSpaceSeparatedValues(forKey: "claims_locales")

            if let additionalAcrValues = remainingParameters?.removeSpaceSeparatedValues(forKey: "acr_values") {
                if self.acrValues.isNil {
                    self.acrValues = additionalAcrValues
                } else {
                    self.acrValues?.append(contentsOf: additionalAcrValues)
                }
            }
            
            if let stringValue = remainingParameters?["prompt"] as? String,
               let prompt = Prompt(rawValue: stringValue)
            {
                self.prompt = prompt
                remainingParameters?.removeValue(forKey: "prompt")
            }
            
            self.additionalParameters = remainingParameters
        }
        
        @_documentation(visibility: internal)
        public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
            var result = additionalParameters ?? [:]

            switch category {
            case .authorization:
                result["state"] = state
                result["response_type"] = "code"

                if let nonce = nonce {
                    result["nonce"] = nonce
                }

                if let maxAge = maxAge {
                    result["max_age"] = Int(maxAge).stringValue
                }

                if let values = $acrValues.rawValue {
                    result["acr_values"] = values
                }

                if let pkce = pkce {
                    result["code_challenge"] = pkce.codeChallenge
                    result["code_challenge_method"] = pkce.method
                }
                
                if let loginHint = loginHint {
                    result["login_hint"] = loginHint
                }
                
                if let idTokenHint = idTokenHint {
                    result["id_token_hint"] = idTokenHint
                }
                
                if let display = display {
                    result["display"] = display
                }
                
                if let prompt = prompt {
                    result["prompt"] = prompt
                }
                
            case .token:
                if let pkce = pkce {
                    result["code_verifier"] = pkce.codeVerifier
                }
                
            case .configuration, .resource, .other: break
            }
            
            return result.nilIfEmpty
        }
    }
    
    /// Defines how a user will be prompted to sign in.
    ///
    /// This is used with the ``BrowserSignin/Option/prompt(_:)`` enumeration. For more information, see the [API documentation for this parameter](https://developer.okta.com/docs/reference/api/oidc/#parameter-details).
    public enum Prompt: String, Sendable {
        /// If an Okta session already exists, the user is silently authenticated. Otherwise, the user is prompted to authenticate.
        case none
        
        /// Display the Okta consent dialog, even if the user has already given consent.
        case consent
        
        /// Always prompt the user for authentication.
        case login
        
        /// The user is always prompted for authentication, and the user consent dialog appears.
        case loginAndConsent = "login consent"
        
        @_documentation(visibility: internal)
        public init?(rawValue: String) {
            switch rawValue.lowercased() {
            case "none":
                self = .none
            case "consent":
                self = .consent
            case "login":
                self = .login
            case "login consent", "consent login":
                self = .loginAndConsent
            default:
                return nil
            }
        }
    }
}
