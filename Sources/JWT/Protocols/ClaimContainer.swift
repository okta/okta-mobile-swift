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
import APIClient

/// Protocol used to define shared behavior when an object can contain claims.
///
/// > Note: This does not apply to JWT, which while it contains claims, it has a different format which includes headers and signatures.
public protocol JSONClaimContainer: HasClaims, JSONDecodable {}

extension JSONClaimContainer {
    public static func decodePayload(from decoder: any Decoder) throws -> [String: any Sendable] {
        let container = try decoder.singleValueContainer()
        let json = try container.decode(JSON.self)
        return json.anyValue as? [String: any Sendable] ?? [:]
    }
}

@_documentation(visibility: private)
extension JSONClaimContainer where Self: Codable {
    public func encode(to encoder: any Encoder) throws {
        let json = try JSON(payload)
        try json.encode(to: encoder)
    }
}
