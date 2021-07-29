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
    /// Object that defines the context for the current authentication session, which is required when a session needs to be resumed.
    @objc(IDXContext)
    public final class Context: NSObject, Codable {
        /// The configuration used when initiating the authentication session.
        @objc public let configuration: Configuration
        
        /// The state value used when the `interact` call was initially made.
        ///
        /// This value can be used to associate a redirect URI to the associated Context that can be used to resume an authentication session.
        @objc public let state: String
        
        /// The interaction handle returned from the `interact` response from the server.
        @objc public let interactionHandle: String
        
        /// The PKCE code verifier value used when initiating the session using the `interact` method.
        @objc public let codeVerifier: String
        
        let version: Version

        internal init(configuration: Configuration,
                      state: String,
                      interactionHandle: String,
                      codeVerifier: String,
                      version: Version = .latest)
        {
            self.configuration = configuration
            self.state = state
            self.interactionHandle = interactionHandle
            self.codeVerifier = codeVerifier
            self.version = version
            
            super.init()
        }
        
        public override var description: String {
            let logger = DebugDescription(self)
            let components = [
                logger.address(),
                "\(#keyPath(state)): \(state)",
                "\(#keyPath(interactionHandle)): \(interactionHandle)",
                "\(#keyPath(codeVerifier)): \(codeVerifier)"
            ]

            return logger.brace(components.joined(separator: "; "))
        }
        
        public override var debugDescription: String {
            let components = [configuration.debugDescription]
                
            return """
            \(description) {
            \(DebugDescription(self).format(components, indent: 4))
            }
            """
        }
    }
}
