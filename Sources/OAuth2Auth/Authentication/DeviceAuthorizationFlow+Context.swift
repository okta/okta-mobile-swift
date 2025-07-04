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
    /// A model representing the context and current state for an authorization session.
    public struct Context: Sendable, AuthenticationContext {
        /// Verification information used to
        public internal(set) var verification: Verification?
        
        /// The ACR values, if any, which should be requested by the client.
        @ClaimCollection
        public var acrValues: [String]?

        /// Any additional query string parameters you would like to supply to the authorization server.
        public var additionalParameters: [String: any APIRequestArgument]?
        
        /// Initializer for creating a context with a custom state string.
        /// - Parameters:
        ///   - acrValues: Optional ACR values to use.
        ///   - additionalParameters: Optional parameters to include in all requests to the Authorization Server.
        public init(acrValues: ClaimCollection<[String]?> = nil,
                    additionalParameters: [String: any APIRequestArgument]? = nil)
        {
            self._acrValues = acrValues
            self.additionalParameters = additionalParameters?.omitting("acr_values")

            if let additionalAcrValues = additionalParameters?.spaceSeparatedValues(for: "acr_values") {
                if self.acrValues.isNil {
                    self.acrValues = additionalAcrValues
                } else {
                    self.acrValues?.append(contentsOf: additionalAcrValues)
                }
            }
        }

        @_documentation(visibility: internal)
        public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
            var result = additionalParameters ?? [:]

            switch category {
            case .authorization:
                if let values = $acrValues.rawValue {
                    result["acr_values"] = values
                }

            case .token:
                result["grant_type"] = GrantType.deviceCode
                
            case .configuration, .resource, .other: break
            }
            
            return result
        }
    }
}
