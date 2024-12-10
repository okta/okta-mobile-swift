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
import AuthFoundation

extension DirectAuthenticationFlow.Configuration {
    public var additionalParameters: [String: any APIRequestArgument]? {
        var result = [String: any APIRequestArgument]()
        
        result["grant_types_supported"] = grantTypesSupported
            .map(\.rawValue)
            .joined(separator: " ")
        
        if let nonce = nonce {
            result["nonce"] = nonce
        }
        
        if let maxAge = maxAge {
            result["max_age"] = Int(maxAge).stringValue
        }

        if let acrValues = acrValues {
            result["acr_values"] = acrValues.joined(separator: " ")
        }
        
        return result
    }
}
