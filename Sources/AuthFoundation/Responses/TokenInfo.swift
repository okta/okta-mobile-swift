//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Introspected token information.
///
/// This provides a convenience mechanism for accessing information related to a token. It supports the ``HasClaims`` protocol, to simplify common operations against introspected information, and to provide consistency with the ``JWT`` class.
///
/// For more information about the members to use, please refer to ``JSONClaimContainer``.
public struct TokenInfo: Sendable, Codable, JSONClaimContainer {
    public typealias ClaimType = JWTClaim
    
    public let payload: [String: any Sendable]

    @_documentation(visibility: internal)
    public init(_ info: [String: any Sendable]) {
        self.payload = info
    }
    
    @_documentation(visibility: internal)
    public init(from decoder: any Decoder) throws {
        self.init(try Self.decodePayload(from: decoder))
    }
    
    /// Indicates if this token is active.
    public var active: Bool? { self["active"] }

    /// The username represented by this token.
    public var username: String? { self["username"] }
}

extension TokenInfo: JSONDecodable {
    @_documentation(visibility: internal)
    public static let jsonDecoder = JSONDecoder()
}
