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

extension TokenExchangeFlow {
    /// A model representing the context and current state for an authorization session.
    public struct Context: AuthenticationContext {
        /// Server audience.
        public var audience: Audience

        /// The ACR values, if any, which should be requested by the client.
        @ClaimCollection
        public var acrValues: [String]?

        /// Any additional query string parameters you would like to supply to the authorization server.
        public var additionalParameters: [String: any APIRequestArgument]?
        
        /// Initializer for creating a context with a custom state string.
        /// - Parameters:
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        ///   - maxAge: The maximum age an ID token can be when authenticating.
        public init(audience: Audience = .default,
                    acrValues: ClaimCollection<[String]?> = nil,
                    additionalParameters: [String: any APIRequestArgument]? = nil)
        {
            self.audience = audience
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
            case .authorization, .token:
                if let values = $acrValues.rawValue {
                    result["acr_values"] = values
                }

                result["audience"] = audience
                result["grant_type"] = GrantType.tokenExchange
                
            case .configuration, .resource, .other: break
            }
            
            return result
        }
    }
}
