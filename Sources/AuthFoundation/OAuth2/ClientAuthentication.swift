//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension OAuth2Client {
    /// Defines the types of authentication the client may use when interacting with the authorization server.
    public enum ClientAuthentication: Codable, Equatable, Hashable {
        /// No client authentication will be made when interacting with the authorization server.
        case none
        
        /// A client secret will be supplied when interacting with the authorization server.
        case clientSecret(String)
        
        /// The additional parameters this authentication type will contribute to outgoing API requests when needed.
        public var additionalParameters: [String: String]? {
            switch self {
            case .none:
                return nil
            case .clientSecret(let secret):
                return ["client_secret": secret]
            }
        }
    }
}
