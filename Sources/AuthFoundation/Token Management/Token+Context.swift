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
    /// Summarizes the context in which a token is valid.
    ///
    /// This includes information such as the client configuration or settings required for token refresh.
    public struct Context: Codable, Sendable, Equatable, Hashable {
        /// The base URL from which this token was issued.
        public let configuration: OAuth2Client.Configuration
        
        /// The developer-assigned tags assigned to this token.
        ///
        /// This property can be used to associate application-specific information about the usage for this token. It can be used to identify which token should be associated with certain parts of your application.
        internal(set) public var tags: [String: String]

        /// Settings required to be supplied to the authorization server when refreshing this token.
        let clientSettings: [String: String]?
        
        init(configuration: OAuth2Client.Configuration, tags: [String: String] = [:], clientSettings: Any?) {
            self.configuration = configuration
            self.tags = tags
            
            if let settings = clientSettings as? [String: String]? {
                self.clientSettings = settings
            } else if let settings = clientSettings as? [CodingUserInfoKey: String] {
                self.clientSettings = settings.clientSettings
            } else {
                self.clientSettings = nil
            }
        }
        
        public init(from decoder: any Decoder) throws {
            if let container = try? decoder.container(keyedBy: Token.Context.CodingKeys.self) {
                self.init(configuration: try container.decode(OAuth2Client.Configuration.self, forKey: .configuration),
                          tags: try container.decodeIfPresent([String: String].self, forKey: .tags) ?? [:],
                          clientSettings: try container.decodeIfPresent([String: String].self, forKey: .clientSettings))
            } else if let configuration = decoder.userInfo[.apiClientConfiguration] as? OAuth2Client.Configuration {
                self.init(configuration: configuration,
                          clientSettings: decoder.userInfo[.clientSettings])
            } else {
                throw TokenError.contextMissing
            }
        }
        
        
    }
}

extension Dictionary where Key == CodingUserInfoKey, Value == String {
    var clientSettings: [String: String] {
        reduce(into: [String: String]()) { (partialResult, tuple: (key: CodingUserInfoKey, value: String)) in
            partialResult[tuple.key.rawValue] = tuple.value
        }
    }
}
