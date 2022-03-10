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
import AuthFoundation
import OktaOAuth2

#if canImport(UIKit) || canImport(AppKit)

extension WebAuthentication {
    private func complete(with result: Result<Token, WebAuthenticationError>) {
        provider = nil
        signInFlow.reset()

        guard let completion = completionBlock else {
            return
        }

        DispatchQueue.main.async {
            completion(result)
        }
        
        completionBlock = nil
    }
    
    private func completeLogout(with result: Result<Void, WebAuthenticationError>) {
        guard let completion = logoutCompletionBlock else {
            return
        }

        DispatchQueue.main.async {
            completion(result)
        }
        
        logoutCompletionBlock = nil
        provider = nil
        signInFlow.reset()
    }
}

extension WebAuthentication: WebAuthenticationProviderDelegate {
    func logout(provider: WebAuthenticationProvider, finished: Bool) {
        if finished {
            completeLogout(with: .success(()))
        }
    }
    
    func logout(provider: WebAuthenticationProvider, received error: Error) {
        let webError: WebAuthenticationError
        if let error = error as? WebAuthenticationError {
            webError = error
        } else if let error = error as? OAuth2Error {
            webError = .oauth2(error: error)
        } else {
            webError = .generic(error: error)
        }
        
        completeLogout(with: .failure(webError))
    }
    
    func authentication(provider: WebAuthenticationProvider, received result: Token) {
        complete(with: .success(result))
    }
    
    func authentication(provider: WebAuthenticationProvider, received error: Error) {
        let webError: WebAuthenticationError
        if let error = error as? WebAuthenticationError {
            webError = error
        } else if let error = error as? OAuth2Error {
            webError = .oauth2(error: error)
        } else {
            webError = .generic(error: error)
        }
        
        complete(with: .failure(webError))
    }
    
    func authenticationShouldUseEphemeralSession(provider: WebAuthenticationProvider) -> Bool {
        ephemeralSession
    }
}

#endif
