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

extension Capability {
    /// Describes the password complexity settings.
    public struct PasswordSettings: AuthenticatorCapability {
        public let daysToExpiry: Int
        public let minLength: Int
        public let minLowerCase: Int
        public let minUpperCase: Int
        public let minNumber: Int
        public let minSymbol: Int
        public let excludeUsername: Bool
        public let excludeAttributes: [String]
        
        init(daysToExpiry: Int,
             minLength: Int,
             minLowerCase: Int,
             minUpperCase: Int,
             minNumber: Int,
             minSymbol: Int,
             excludeUsername: Bool,
             excludeAttributes: [String])
        {
            self.daysToExpiry = daysToExpiry
            self.minLength = minLength
            self.minLowerCase = minLowerCase
            self.minUpperCase = minUpperCase
            self.minNumber = minNumber
            self.minSymbol = minSymbol
            self.excludeUsername = excludeUsername
            self.excludeAttributes = excludeAttributes
        }
    }
}
