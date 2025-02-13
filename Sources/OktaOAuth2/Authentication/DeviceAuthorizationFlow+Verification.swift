//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension DeviceAuthorizationFlow {
    /// Represents the user verification response of the ``DeviceAuthorizationFlow`` authentication flow.
    ///
    /// The values contained within this verification object should be used to present the user with the code and URL to visit to authorize their device.
    public struct Verification: Decodable, Equatable, Expires {
        let deviceCode: String
        var interval: TimeInterval
        
        /// The date this context was created.
        public let issuedAt: Date?

        /// The code that should be displayed to the user.
        public let userCode: String
        
        /// The URI the user should be prompted to open in order to authorize the application.
        public let verificationUri: URL
        
        /// A convenience URI that combines the ``verificationUri`` and the ``userCode``, to make a clickable link.
        public let verificationUriComplete: URL?
        
        /// The time interval after which the authorization context will expire.
        public let expiresIn: TimeInterval
        
        enum CodingKeys: String, CodingKey, CaseIterable {
            case issuedAt
            case userCode
            case verificationUri
            case verificationUriComplete
            case expiresIn
            case deviceCode
            case interval
        }
        
        @_documentation(visibility: internal)
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            issuedAt = try container.decodeIfPresent(Date.self, forKey: .issuedAt) ?? Date()
            deviceCode = try container.decode(String.self, forKey: .deviceCode)
            userCode = try container.decode(String.self, forKey: .userCode)
            verificationUri = try container.decode(URL.self, forKey: .verificationUri)
            verificationUriComplete = try container.decodeIfPresent(URL.self, forKey: .verificationUriComplete)
            expiresIn = try container.decode(TimeInterval.self, forKey: .expiresIn)
            interval = try container.decodeIfPresent(TimeInterval.self, forKey: .interval) ?? 5.0
        }
    }
}
