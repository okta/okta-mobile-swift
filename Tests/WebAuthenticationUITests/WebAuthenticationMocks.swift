//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

#if canImport(UIKit) || canImport(AppKit)

import XCTest
@testable import AuthFoundation
@testable import OktaOAuth2
@testable import WebAuthenticationUI

class WebAuthenticationMock: WebAuthentication {
    override func createWebAuthenticationProvider(loginFlow: AuthorizationCodeFlow,
                                                  logoutFlow: SessionLogoutFlow?,
                                                  from window: WebAuthentication.WindowAnchor?,
                                                  delegate: WebAuthenticationProviderDelegate) -> WebAuthenticationProvider? {
        return WebAuthenticationProviderMock(loginFlow: loginFlow, logoutFlow: logoutFlow, delegate: delegate)
    }
}


class WebAuthenticationProviderMock: WebAuthenticationProvider {
    var loginFlow: AuthorizationCodeFlow
    var logoutFlow: SessionLogoutFlow?
    var delegate: WebAuthenticationProviderDelegate?
    
    enum State {
        case initialized, started, cancelled, logout
    }
    
    var state: State = .initialized
    
    init(loginFlow: AuthorizationCodeFlow, logoutFlow: SessionLogoutFlow?, delegate: WebAuthenticationProviderDelegate) {
        self.loginFlow = loginFlow
        self.logoutFlow = logoutFlow
        self.delegate = delegate
    }
    
    func start(context: AuthorizationCodeFlow.Context?, additionalParameters: [String: String]?) {
        state = .started
        
        loginFlow.start(with: nil, additionalParameters: additionalParameters) { result in
            
        }
    }
    
    func logout(context: SessionLogoutFlow.Context, additionalParameters: [String: String]?) {
        state = .started
        
        try? logoutFlow?.start(idToken: "idToken", additionalParameters: additionalParameters) { result in
            
        }
    }
    
    func cancel() {
        state = .cancelled
    }
}

#endif
