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
    public struct Metadata: JSONClaimContainer {
        public typealias ClaimType = JWTClaim

        /// The unique ID for the token.
        public let id: String
        
        /// Developer-assigned tags.
        public let tags: [String: String]
        
        /// The raw contents of the claim payload for this token.
        public let payload: [String: Any]
        
        private let payloadData: Data?
        init(token: Token, tags: [String: String]) {
            self.id = token.id
            self.tags = tags
            
            var payload = [String: Any]()
            var payloadData: Data?
            
            if let idToken = token.idToken {
                let tokenComponents = JWT.tokenComponents(from: idToken.rawValue)
                if tokenComponents.count == 3 {
                   payloadData = Data(base64Encoded: tokenComponents[1])
                }
            }
            
            if let payloadData = payloadData,
               let payloadInfo = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
            {
                payload = payloadInfo
            }
            
            self.payload = payload
            self.payloadData = payloadData
        }
        
        init(id: String) {
            self.id = id
            self.tags = [:]
            self.payload = [:]
            self.payloadData = nil
        }
    }
}

extension Token.Metadata {
    public static var jsonDecoder = JSONDecoder()
}

extension Token.Metadata: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.payloadData = try container.decodeIfPresent(Data.self, forKey: .payload)
        self.id = try container.decode(String.self, forKey: .id)
        self.tags = try container.decode([String: String].self, forKey: .tags)
        
        if let data = self.payloadData,
           let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            self.payload = payload
        } else {
            self.payload = [:]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tags, forKey: .tags)
        try container.encode(payloadData, forKey: .payload)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, tags, payload
    }
}
