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
import AuthFoundation

/// Defines the common properties and functions shared between factor types.
protocol AuthenticationFactor {
    /// The grant type supported by this factor.
    var grantType: GrantType { get }
    
    /// Parameters to include in the API request.
    var tokenParameters: [String: Any]? { get }
    
    /// Returns a step handler capable of handling this authentication factor.
    /// - Parameters:
    ///   - flow: The current flow for this authentication step.
    ///   - openIdConfiguration: OpenID configuration for this org.
    ///   - loginHint: The login hint for this session.
    ///   - factor: The factor for the step to process.
    /// - Returns: A step handler capable of processing this authentication factor.
    func stepHandler(flow: DirectAuthenticationFlow,
                     openIdConfiguration: OpenIdConfiguration,
                     loginHint: String?,
                     currentStatus: DirectAuthenticationFlow.Status?,
                     factor: Self) throws -> any StepHandler
}
