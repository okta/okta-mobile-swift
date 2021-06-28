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

extension IDXClient {
    /// Container that represents a collection of authenticators, providing conveniences for quickly accessing relevant objects.
    @objc(IDXAuthenticatorCollection)
    public class AuthenticatorCollection: NSObject {
        /// The current authenticator, if one is actively being enrolled or authenticated.
        @objc public var current: Authenticator? {
            allAuthenticators.first { $0.state == .authenticating || $0.state == .enrolling }
        }
        
        /// The array of currently-enrolled authenticators.
        @objc public var enrolled: [Authenticator] {
            allAuthenticators.filter { $0.state == .enrolled }
        }
        
        /// Access authenticators based on their type.
        @objc public subscript(type: Authenticator.Kind) -> Authenticator? {
            allAuthenticators.first(where: { $0.type == type })
        }
        
        var allAuthenticators: [IDXClient.Authenticator] {
            authenticators
        }
        
        let authenticators: [IDXClient.Authenticator]
        init(authenticators: [IDXClient.Authenticator]?) {
            self.authenticators = authenticators ?? []

            super.init()
        }
    }
    
    class WeakAuthenticatorCollection: AuthenticatorCollection {
        override var allAuthenticators: [IDXClient.Authenticator] {
            weakAuthenticators.compactMap { $0.object }
        }
        
        let weakAuthenticators: [Weak<IDXClient.Authenticator>]
        override init(authenticators: [IDXClient.Authenticator]?) {
            weakAuthenticators = authenticators?.map({ (authenticator) in
                Weak(object: authenticator)
            }) ?? []
            
            super.init(authenticators: nil)
        }
    }
}
