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

/// Represents information describing the available authenticators and enrolled authenticators.
///
/// Instances of this class are used to identify the type of authenticator, or factor, that is associated with a user. These may be associated with form fields (for example, when selecting an authenticator to verify or to enrol in), with a ``Remediation`` (when challenging an authenticator for a verification code), or with an overall ``Response`` to indicate which authenticators have been enrolled, are being enrolled.
public final class Authenticator: Sendable, Equatable, Hashable {
    /// Unique identifier for this enrollment
    public let id: String?
    
    /// The user-visible name to use for this authenticator enrollment.
    public let displayName: String?
    
    /// The type of this authenticator, or ``Kind/unknown`` if the type isn't represented by this enumeration.
    public let type: Kind
    
    /// The key name for the authenticator
    public let key: String?
    
    /// Indicates the state of this authenticator, either being an available authenticator, an enrolled authenticator, authenticating, or enrolling.
    public let state: State
    
    /// Describes the various methods this authenticator can perform.
    public let methods: [Method]?
    
    /// Set of objects that describe the capabilities this authenticator may have.
    public let capabilities: [CapabilityType]

    @_documentation(visibility: internal)
    public static func == (lhs: Authenticator, rhs: Authenticator) -> Bool {
        lhs.id == rhs.id &&
        lhs.displayName == rhs.displayName &&
        lhs.type == rhs.type &&
        lhs.key == rhs.key &&
        lhs.state == rhs.state &&
        lhs.methods == rhs.methods
    }

    @_documentation(visibility: internal)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
        hasher.combine(type)
        hasher.combine(key)
        hasher.combine(state)
        hasher.combine(methods)
        hasher.combine(capabilities)
    }

    nonisolated(unsafe) private weak var flow: (any InteractionCodeFlowAPI)?
    let jsonPaths: [String]
    init(flow: any InteractionCodeFlowAPI,
         v1JsonPaths: [String],
         state: State,
         id: String?,
         displayName: String?,
         type: Authenticator.Kind,
         key: String?,
         methods: [[String: String]]?,
         capabilities: [any Capability])
    {
        self.flow = flow
        self.jsonPaths = v1JsonPaths
        self.state = state
        self.id = id
        self.displayName = displayName
        self.type = type
        self.key = key
        self.methods = methods?
            .compactMap { $0["type"] }
            .compactMap(Method.init(rawValue:))
        self.capabilities = capabilities.compactMap { CapabilityType($0) }
    }
}
