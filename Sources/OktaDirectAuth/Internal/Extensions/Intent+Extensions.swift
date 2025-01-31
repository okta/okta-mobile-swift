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

extension DirectAuthenticationFlow.Intent: ProvidesOAuth2Parameters {
    @_documentation(visibility: private)
    public func parameters(for category: OAuth2APIRequestCategory) -> [String: any APIRequestArgument]? {
        guard case .recovery = self else { return nil }
        
        switch category {
        case .authorization, .token:
            return [
                "scope": "okta.myAccount.password.manage",
                "intent": "recovery",
            ]
        case .configuration, .resource, .other:
            return nil
        }
    }
}
