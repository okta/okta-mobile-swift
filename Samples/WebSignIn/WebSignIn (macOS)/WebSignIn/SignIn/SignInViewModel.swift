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
import Combine
import WebAuthenticationUI
import AuthenticationServices

final class SignInViewModel: ObservableObject {
    var clientID: String? { auth?.signInFlow.client.configuration.clientId }
    var isConfigured: Bool { auth?.signInFlow.client.configuration.clientId != nil }
    
    @Published var presentError = false
    @Published var ephemeralSession = false
    @Published private(set) var signInError: Error?
    @Published private(set) var signedIn = Credential.default != nil

    private let auth = WebAuthentication.shared
    private var cancellableSet: Set<AnyCancellable> = []
 
    init() {
        $signInError
            .map { $0 != nil }
            .assign(to: &$presentError)
        
        $ephemeralSession
            .sink { self.auth?.ephemeralSession = $0 }
            .store(in: &cancellableSet)
    }
    
    func signIn() {
        auth?.ephemeralSession = ephemeralSession
        auth?.signIn(from: ASPresentationAnchor()) { result in
            switch result {
            case .success(let token):
                Credential.default = Credential(token: token)
                self.signedIn = true
            case .failure(let error):
                self.signInError = error
                self.signedIn = false
            }
        }
    }
}
