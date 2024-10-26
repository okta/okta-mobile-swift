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
import JWT

extension Token {
    /// Describes the metadata associated with a token.
    ///
    /// This is used when storing tags and claims associated with tokens, as well as through the ``Credential/find(where:prompt:authenticationContext:)`` method.
    public struct Metadata: JSONClaimContainer {
        public typealias ClaimType = JWTClaim

        /// The unique ID for the token.
        public let id: String
        
        /// Developer-assigned tags.
        public let tags: [String: String]
        
        /// The base URL from which this token was issued.
        public let configuration: OAuth2Client.Configuration?

        /// The raw contents of the claim payload for this token.
        public let payload: [String: any Sendable]
        
        private let payloadData: Data?
        init(token: Token, tags: [String: String], configuration: OAuth2Client.Configuration?) {
            self.id = token.id
            self.tags = tags
            self.configuration = configuration
            (self.payloadData, self.payload) = token.metadataPayload
        }
        
        init(token: Token) {
            self.id = token.id
            self.tags = token.context.tags
            self.configuration = token.context.configuration
            (self.payloadData, self.payload) = token.metadataPayload
        }
        
        init(id: String, configuration: OAuth2Client.Configuration?) {
            self.id = id
            self.tags = [:]
            self.configuration = configuration
            self.payload = [:]
            self.payloadData = nil
        }
    }
}

extension Token {
    var metadataPayload: (Data?, [String: any Sendable]) {
        guard let idToken = idToken else {
            return (nil, [:])
        }
        
        let tokenComponents = JWT.tokenComponents(from: idToken.rawValue)
        guard tokenComponents.count == 3,
              let payloadData = Data(base64Encoded: tokenComponents[1]),
              let payloadInfo = try? JSONSerialization.jsonObject(with: payloadData) as? [String: any Sendable]
        else {
            return (nil, [:])
        }

        return (payloadData, payloadInfo)
    }
}

extension Token.Metadata {
    public static let jsonDecoder = JSONDecoder()
}

extension Token.Metadata: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.payloadData = try container.decodeIfPresent(Data.self, forKey: .payload)
        self.id = try container.decode(String.self, forKey: .id)
        self.tags = try container.decode([String: String].self, forKey: .tags)
        self.configuration = try container.decodeIfPresent(OAuth2Client.Configuration.self, forKey: .configuration)
        
        if let data = self.payloadData,
           let payload = try JSONSerialization.jsonObject(with: data) as? [String: any Sendable]
        {
            self.payload = payload
        } else {
            self.payload = [:]
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tags, forKey: .tags)
        try container.encode(configuration, forKey: .configuration)
        try container.encode(payloadData, forKey: .payload)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, tags, configuration, payload
    }
}

extension Token.Metadata: Equatable {
    public static func == (lhs: Token.Metadata, rhs: Token.Metadata) -> Bool {
        return (lhs.id == rhs.id &&
                lhs.tags == rhs.tags &&
                lhs.payloadData == rhs.payloadData)
    }
}
