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

extension Response {
    /// Provides information about the user being authenticated.
    public struct User {
        /// Unique identifier for this user.
        public let id: String
        
        /// Username for this user.
        ///
        /// This value may not be available at all times.
        public let username: String?
        
        /// Profile information for this user.
        ///
        /// This value may not be available at all times.
        public let profile: Profile?
    }
}

extension Response.User {
    /// Optional profile information that describes the user.
    public struct Profile {
        /// The user's first name.
        public let firstName: String?
        
        /// The user's last name.
        public let lastName: String?
        
        /// The user's time zone.
        public let timeZone: TimeZone?
        
        /// The user's locale.
        public let locale: Locale?
    }
}
