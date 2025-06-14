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

extension SessionLogoutFlow {
    /// A model representing the context and current state for a logout session.
    public struct Context: Sendable, Equatable {
        /// The state string to use when creating an logout URL.
        public let state: String
        
        /// The ID token hint to use when signing out.
        public var idToken: String? {
            didSet {
                logoutURL = nil
            }
        }
        
        /// A hint about the identifier used to log out (analogous to the ``AuthorizationCodeFlow/Context-swift.struct/loginHint`` parameter).
        public var logoutHint: String? {
            didSet {
                logoutURL = nil
            }
        }
        
        /// Any additional query string parameters you would like to supply to the authorization server.
        public var additionalParameters: [String: any APIRequestArgument]? {
            didSet {
                logoutURL = nil
            }
        }

        /// The current logout URL, or `nil` if one has not yet been generated.
        public internal(set) var logoutURL: URL?
        
        /// Initializer for creating a context.
        /// - Parameters:
        ///   - idToken: The ID token hint to use when signing out.
        ///   - logoutHint: A hint about the identifier used to log out.
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        ///   - additionalParameters: Any additional query string parameters you would like to supply to the authorization server.
        public init(idToken: String? = nil,
                    logoutHint: String? = nil,
                    state: String? = nil,
                    additionalParameters: [String: any APIRequestArgument]? = nil)
        {
            self.idToken = idToken
            self.logoutHint = logoutHint
            self.state = state ?? UUID().uuidString
            self.additionalParameters = additionalParameters
        }

        /// Initializer for creating a context.
        /// - Parameters:
        ///   - token: The token to provide information about which user to sign out.
        ///   - logoutHint: A hint about the identifier used to log out.
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        ///   - additionalParameters: Any additional query string parameters you would like to supply to the authorization server.
        public init(token: Token,
                    logoutHint: String? = nil,
                    state: String? = nil,
                    additionalParameters: [String: any APIRequestArgument]? = nil)
        {
            self.init(idToken: token.idToken?.rawValue,
                      logoutHint: logoutHint,
                      state: state,
                      additionalParameters: additionalParameters)
        }
        
        @_documentation(visibility: internal)
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.state == rhs.state
            && lhs.idToken == rhs.idToken
            && lhs.logoutHint == rhs.logoutHint
            && lhs.additionalParameters?.mapValues(\.stringValue) == rhs.additionalParameters?.mapValues(\.stringValue)
            && lhs.logoutURL == rhs.logoutURL
        }
    }
}
