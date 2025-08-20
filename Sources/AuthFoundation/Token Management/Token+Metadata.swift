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

extension Token {
    /// Describes the metadata associated with a token.
    ///
    /// This is used when storing tags and claims associated with tokens, as well as through the ``Credential/find(where:prompt:authenticationContext:)`` method.
    public struct Metadata: Sendable, HasClaims {
        public typealias ClaimType = JWTClaim

        /// The unique ID for the token.
        public let id: String
        
        /// Developer-assigned tags.
        public let tags: [String: String]
        
        /// The raw JSON content of the claim payload for this token.
        public let payload: JSON
        
        @_documentation(visibility: internal)
        public var claimContent: [String: any Sendable] { payload.claimContent }

        init(token: Token, tags: [String: String]) throws {
            self.id = token.id
            self.tags = tags
            self.payload = token.idToken?.payload ?? JSON(.object([:]))
        }
        
        init(id: String) {
            self.id = id
            self.tags = [:]
            self.payload = JSON(.object([:]))
        }
    }
}

extension Token.Metadata {
    @_documentation(visibility: internal)
    public static let jsonDecoder = JSONDecoder()
}

extension Token.Metadata: Codable {
    @_documentation(visibility: internal)
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let jsonData = try container.decodeIfPresent(Data.self, forKey: .payload) {
            self.payload = try JSON(jsonData)
        } else {
            self.payload = JSON(.object([:]))
        }
        
        self.id = try container.decode(String.self, forKey: .id)
        self.tags = try container.decode([String: String].self, forKey: .tags)
    }
    
    @_documentation(visibility: internal)
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tags, forKey: .tags)
        try container.encode(try payload.data, forKey: .payload)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, tags, payload
    }
}
