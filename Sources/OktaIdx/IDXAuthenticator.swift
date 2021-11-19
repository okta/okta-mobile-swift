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
    /// Represents information describing the available authenticators and enrolled authenticators.
    @objc(IDXAuthenticator)
    public class Authenticator: NSObject {
        /// Unique identifier for this enrollment
        @objc(identifier)
        public let id: String?

        /// The user-visible name to use for this authenticator enrollment.
        @objc public let displayName: String?

        /// The type of this authenticator, or `unknown` if the type isn't represented by this enumeration.
        @objc public let type: Kind
        
        /// The key name for the authenticator
        @objc public let key: String?
        
        /// Indicates the state of this authenticator, either being an available authenticator, an enrolled authenticator, authenticating, or enrolling.
        @objc public let state: State

        /// Describes the various methods this authenticator can perform.
        @nonobjc public let methods: [Method]?
        
        /// Describes the various methods this authenticator can perform, as string values.
        @objc public let methodNames: [String]?
        
        public let capabilities: [AuthenticatorCapability]
        
        // TODO: deviceKnown?
        // TODO: credentialId?
        
        private weak var client: IDXClientAPI?
        let jsonPaths: [String]
        init(client: IDXClientAPI,
             v1JsonPaths: [String],
             state: State,
             id: String?,
             displayName: String?,
             type: String,
             key: String?,
             methods: [[String:String]]?,
             capabilities: [AuthenticatorCapability])
        {
            self.client = client
            self.jsonPaths = v1JsonPaths
            self.state = state
            self.id = id
            self.displayName = displayName
            self.type = Kind(string: type)
            self.key = key
            self.methods = methods?.compactMap {
                guard let type = $0["type"] else { return nil }
                return Method(string: type)
            }
            self.methodNames = methods?.compactMap { $0["type"] }
            self.capabilities = capabilities
            
            super.init()
        }
        
        public override var description: String {
            let logger = DebugDescription(self)
            let components = [
                logger.address(),
                "\(#keyPath(type)): \(type.rawValue)",
                "\(#keyPath(state)): \(state.rawValue)",
            ]
            
            return logger.brace(components.joined(separator: "; "))
        }
        
        public override var debugDescription: String {
            let components = [
                "\(#keyPath(id)): \(id ?? "-")",
                "\(#keyPath(displayName)): \(displayName ?? "-")",
                "\(#keyPath(key)): \(key ?? "-")",
                "\(#keyPath(methodNames)): \(methodNames ?? [])"
            ]
            
            return """
            \(description) {
            \(DebugDescription(self).format(components, indent: 4))
            }
            """
        }
    }
}
