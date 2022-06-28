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

extension InteractionCodeFlow {
    /// Object that defines the context for the current authentication session, which is required when a session needs to be resumed.
    public struct Context: Codable, Equatable {
        /// The state value used when the ``InteractionCodeFlow/start(options:completion:)`` call was initially made.
        ///
        /// This value can be used to associate a redirect URI to the associated Context that can be used to resume an authentication session.
        public let state: String
        
        /// The interaction handle returned from the `interact` response from the server.
        public let interactionHandle: String
        
        /// The PKCE settings used when initiating the session using the ``InteractionCodeFlow/start(options:completion:)`` method.
        public let pkce: PKCE

        /// Initializer for creating a context with a custom state string.
        /// - Parameter state: State string to use, or `nil` to accept an automatically generated default.
        public init(interactionHandle: String, state: String? = nil) throws {
            guard let pkce = PKCE() else {
                throw InteractionCodeFlowError.platformUnsupported
            }
            
            self.init(interactionHandle: interactionHandle,
                      state: state ?? UUID().uuidString,
                      pkce: pkce)
        }
        
        init(interactionHandle: String, state: String, pkce: PKCE) {
            self.interactionHandle = interactionHandle
            self.state = state
            self.pkce = pkce
        }
    }
}
