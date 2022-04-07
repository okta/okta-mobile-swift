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
    /// Summarizes the context in which a token is valid.
    ///
    /// This includes information such as the client configuration or settings required for token refresh.
    public struct Context: Codable, Equatable, Hashable {
        /// The base URL from which this token was issued.
        public let configuration: OAuth2Client.Configuration
        
        /// Settings required to be supplied to the authorization server when refreshing this token.
        let clientSettings: [String: String]?
        
        init(configuration: OAuth2Client.Configuration, clientSettings: Any?) {
            self.configuration = configuration
            
            if let settings = clientSettings as? [String: String]? {
                self.clientSettings = settings
            }
            
            else if let settings = clientSettings as? [CodingUserInfoKey: String] {
                self.clientSettings = settings.reduce(into: [String: String]()) { (partialResult, tuple: (key: CodingUserInfoKey, value: String)) in
                    partialResult[tuple.key.rawValue] = tuple.value
                }
            } else {
                self.clientSettings = nil
            }
        }
    }
}
