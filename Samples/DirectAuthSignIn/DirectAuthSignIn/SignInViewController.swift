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

import UIKit
import SwiftUI
import AuthFoundation
import OktaDirectAuth

class SignInViewController: UIHostingController<SignInView> {
    required init?(coder aDecoder: NSCoder) {
        let flow: DirectAuthenticationFlow?
        
        // Workaround to remove the `device_sso` scope, when included in the property list.
        if let configuration = try? OAuth2Client.PropertyListConfiguration(),
           let ssoRange = configuration.scopes.range(of: "device_sso")
        {
            var scopes = configuration.scopes
            scopes.removeSubrange(ssoRange)
            
            flow = DirectAuthenticationFlow(issuer: configuration.issuer,
                                            clientId: configuration.clientId,
                                            scopes: scopes)
        } else {
            flow = try? DirectAuthenticationFlow()
        }
        
        super.init(coder: aDecoder, rootView: SignInView(flow: flow))
    }
}
