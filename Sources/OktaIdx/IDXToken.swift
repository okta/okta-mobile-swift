//
// Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension IDXClient {
    /// Access tokens created as a result of exchanging a successful workflow response.
    @objc(IDXToken)
    public final class Token: NSObject, Codable {
        /// The access token to use.
        @objc public let accessToken: String
        
        /// The refresh token, if available.
        @objc public let refreshToken: String?
        
        /// The time interval after which this token will expire.
        @objc public let expiresIn: TimeInterval
        
        /// The ID token JWT string.
        @objc public let idToken: String?
        
        /// The access scopes for this token.
        @objc public let scope: String
        
        /// The type of this token.
        @objc public let tokenType: String

        /// The configuration used when this token was created
        @objc public let configuration: Configuration

        /// The possible token types that can be revoked.
        @objc public enum RevokeType: Int {
            case refreshToken
            case accessAndRefreshToken
        }
        
        /// Revokes the token.
        /// - Parameters:
        ///   - type: The type to revoke (e.g. access token, or refresh token).
        ///   - completion: Completion handler for when the token is revoked.
        @objc(revokeToken:completion:)
        public func revoke(type: Token.RevokeType = .accessAndRefreshToken, completion: @escaping(_ successful: Bool, _ error: Error?) -> Void) {
            let selectedToken: String?
            switch type {
            case .refreshToken:
                selectedToken = refreshToken
            case .accessAndRefreshToken:
                selectedToken = accessToken
            }
            
            guard let tokenString = selectedToken else {
                completion(false, IDXClientError.invalidParameter(name: "token"))
                return
            }
            
            Token.revoke(token: tokenString, type: type, configuration: configuration, completion: completion)
        }

        /// Revokes the given token using the string value of the token.
        /// - Parameters:
        ///   - token: Token string to revoke.
        ///   - type: The type to revoke (e.g. access token, or refresh token).
        ///   - configuration: The client configuration used when the token was created.
        ///   - completion: Completion handler for when the token is revoked.
        @objc(revokeToken:type:configuration:completion:)
        public static func revoke(token: String,
                                  type: Token.RevokeType,
                                  configuration: Configuration,
                                  completion: @escaping(_ successful: Bool, _ error: Error?) -> Void)
        {
            let api = IDXClient.Version.latest.clientImplementation(with: configuration)
            revoke(token: token, type: type, api: api, completion: completion)
        }
        
        /// Refreshes the token.
        ///
        /// If no refresh token is available, or the tokens have been revoked, an error will be returned.
        ///
        /// > *Note:* Depending on organization or policy settings, the values contained within the token may or may not differ once the token is refreshed. Therefore, it may be necessary to save the newly-refeshed object for use in future requests.
        /// - Parameters:
        ///   - token: The new token object if the refresh was successful.
        ///   - error: An error object if the refresh was unsuccessful.
        ///   - completion: Completion handler for when the token is revoked.
        @objc public func refresh(completion: @escaping(_ token: Token?, _ error: Error?) -> Void)
        {
            let api = IDXClient.Version.latest.clientImplementation(with: configuration)
            api.refresh(token: self) { (token, error) in
                completion(token, error)
            }
        }

        static func revoke(token: String,
                           type: Token.RevokeType,
                           api: IDXClientAPIImpl,
                           completion: @escaping(_ successful: Bool, _ error: Error?) -> Void)
        {
            api.revoke(token: token, type: type.tokenTypeHint) { (success, error) in
                completion(success, error)
            }
        }

        internal init(accessToken: String,
                      refreshToken: String?,
                      expiresIn: TimeInterval,
                      idToken: String?,
                      scope: String,
                      tokenType: String,
                      configuration: Configuration)
        {
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.expiresIn = expiresIn
            self.idToken = idToken
            self.scope = scope
            self.tokenType = tokenType
            self.configuration = configuration
            
            super.init()
        }
    }
}
