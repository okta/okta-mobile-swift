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

protocol WebAuthenticationProvider {
    var loginFlow: AuthorizationCodeFlow { get }
    var logoutFlow: SessionLogoutFlow? { get }
    var delegate: WebAuthenticationProviderDelegate? { get }

    func start(context: AuthorizationCodeFlow.Context?, additionalParameters: [String: String]?)
    func logout(context: SessionLogoutFlow.Context, additionalParameters: [String: String]?)
    func cancel()
}

protocol WebAuthenticationProviderDelegate: AnyObject {
    func authentication(provider: WebAuthenticationProvider, received token: Token)
    func authentication(provider: WebAuthenticationProvider, received error: Error)
    
    func logout(provider: WebAuthenticationProvider, finished: Bool)
    func logout(provider: WebAuthenticationProvider, received error: Error)
    
    @available(iOS 13.0, macOS 10.15, macCatalyst 13.0, *)
    func authenticationShouldUseEphemeralSession(provider: WebAuthenticationProvider) -> Bool
}

#endif
