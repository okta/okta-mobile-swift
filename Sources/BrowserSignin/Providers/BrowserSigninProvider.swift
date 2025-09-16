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
import AuthFoundation
import OAuth2Auth

extension BrowserSignin {
    /// Protocol used to represent a specific provider type for use in presenting a browser.
    ///
    /// > Important: The default implementation will use the most appropriate browser session for use when authenticating. This facility should only be used when a built-in browser capability is unavailable in your target environment.
    nonisolated public protocol Provider: Sendable {
        /// Used by ``BrowserSignin`` when it determines a browser should be presented to the user.
        /// - Parameters:
        ///   - authorizeUrl: Authorization URL to open within the browser.
        ///   - redirectUri: The redirect URI configured for the client.
        /// - Returns: The final URI the browser redirects to which matches the `redirectUri` parameter.
        func open(authorizeUrl: URL, redirectUri: URL) async throws -> URL
        
        /// Used by ``BrowserSignin`` when the browser window should be canceled and closed.
        func cancel()
    }
    
    /// Protocol used to customize the presentation of the browser sign in interface.
    ///
    /// > Important: The default implementation will use the most appropriate browser session for use when authenticating. This facility should only be used when a built-in browser capability is unavailable in your target environment.
    nonisolated public protocol ProviderFactory: Sendable {
        /// Creates an object conforming to ``BrowserSignin/Provider`` for use in presenting a browser to the user when they are signing in.
        /// - Parameters:
        ///   - browserSignin: The ``BrowserSignin`` instance triggering this operation.
        ///   - window: The window anchor the sign-in is initiated from.
        ///   - options: The options used to control the sign in provider's behavior.
        /// - Returns: ``BrowserSignin/Provider`` that is capable of signing in, or `nil` if browser sign in is unsupported on this platform.
        nonisolated static func createWebAuthenticationProvider(
            for browserSignin: BrowserSignin,
            from window: BrowserSignin.WindowAnchor?,
            options: BrowserSignin.Option) async throws -> (any Provider)?
    }
}
