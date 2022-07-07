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

import Foundation
import OktaOAuth2

class DeviceAuthorizationFlowDelegateRecorder: DeviceAuthorizationFlowDelegate {
    var context: DeviceAuthorizationFlow.Context?
    var token: Token?
    var error: OAuth2Error?
    var url: URL?
    var started = false
    var finished = false
    
    func authenticationStarted<Flow: DeviceAuthorizationFlow>(flow: Flow) {
        started = true
    }
    
    func authenticationFinished<Flow: DeviceAuthorizationFlow>(flow: Flow) {
        finished = true
    }

    func authentication<Flow>(flow: Flow, received context: DeviceAuthorizationFlow.Context) {
        self.context = context
    }
    
    func authentication<Flow>(flow: Flow, received token: Token) {
        self.token = token
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        self.error = error
    }

    func authentication<Flow: DeviceAuthorizationFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents) {
        urlComponents.fragment = "customizedUrl"
    }
    
    func authentication<Flow: DeviceAuthorizationFlow>(flow: Flow, shouldAuthenticateUsing url: URL) {
        self.url = url
    }
}
