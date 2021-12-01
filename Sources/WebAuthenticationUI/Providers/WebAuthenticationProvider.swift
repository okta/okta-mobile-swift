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
import OktaOAuth2

protocol WebAuthenticationProvider {
    var flow: AuthorizationCodeFlow { get }
    var delegate: WebAuthenticationProviderDelegate { get }

    var canStart: Bool { get }

    func start(from anchor: WebAuthentication.WindowAnchor?)
    func cancel()
}

protocol WebAuthenticationProviderDelegate {
    func authentication(provider: WebAuthenticationProvider, received token: Token)
    func authentication(provider: WebAuthenticationProvider, received error: Error)
}

extension WebAuthentication {
    static func createWebAuthenticationProvider(flow: AuthorizationCodeFlow,
                                                delegate: WebAuthenticationProviderDelegate) -> WebAuthenticationProvider?
    {
        #if canImport(AuthenticationServices)
        if #available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *) {
            return AuthenticationServicesProvider(flow: flow, delegate: delegate)
        }
        #endif
        
        return nil
    }
}
