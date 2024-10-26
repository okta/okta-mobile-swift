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

import AuthFoundation
import OktaOAuth2

#if canImport(UIKit) || canImport(AppKit)

protocol WebAuthenticationProvider: Sendable {
    var loginFlow: AuthorizationCodeFlow { get }
    var logoutFlow: SessionLogoutFlow? { get }
    var delegate: (any WebAuthenticationProviderDelegate)? { get }

    func start(context: AuthorizationCodeFlow.Context?, additionalParameters: [String: String]?)
    func logout(context: SessionLogoutFlow.Context, additionalParameters: [String: String]?)
    func cancel()
}

protocol WebAuthenticationProviderDelegate: AnyObject, Sendable {
    func authentication(provider: any WebAuthenticationProvider, received token: Token)
    func authentication(provider: any WebAuthenticationProvider, received error: any Error)
    
    func logout(provider: any WebAuthenticationProvider, finished: Bool)
    func logout(provider: any WebAuthenticationProvider, received error: any Error)
    
    @available(iOS 13.0, macOS 10.15, macCatalyst 13.0, *)
    func authenticationShouldUseEphemeralSession(provider: any WebAuthenticationProvider) -> Bool
}

#endif
