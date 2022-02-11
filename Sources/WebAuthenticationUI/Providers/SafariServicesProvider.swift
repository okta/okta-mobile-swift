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

#if os(iOS) && canImport(SafariServices)

import AuthFoundation
import OktaOAuth2
import SafariServices

@available(iOS, introduced: 11.0, deprecated: 12.0)
class SafariServicesProvider: NSObject, WebAuthenticationProvider {
    let flow: AuthorizationCodeFlow
    private(set) weak var delegate: WebAuthenticationProviderDelegate?

    private(set) var authenticationSession: SFAuthenticationSession?
    
    init(flow: AuthorizationCodeFlow,
         delegate: WebAuthenticationProviderDelegate)
    {
        self.flow = flow
        self.delegate = delegate
        
        super.init()
        
        self.flow.add(delegate: self)
    }
    
    deinit {
        self.flow.remove(delegate: self)
    }
    
    func start(context: AuthorizationCodeFlow.Context?) {
        guard let delegate = delegate else { return }
        
        do {
            try flow.resume(with: context)
        } catch {
            delegate.authentication(provider: self, received: error)
        }
    }
    
    func finish(context: AuthorizationLogoutFlow.Context?) {
        
    }
    
    func authenticate(using url: URL) {
        authenticationSession = SFAuthenticationSession(
            url: url,
            callbackURLScheme: flow.redirectUri.scheme,
            completionHandler: { [weak self] url, error in
                self?.process(url: url, error: error)
            })
        
        authenticationSession?.start()
    }
    
    func process(url: URL?, error: Error?) {
        defer { authenticationSession = nil }
        
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == SFAuthenticationErrorDomain,
               nsError.code == SFAuthenticationError.canceledLogin.rawValue
            {
                received(error: .userCancelledLogin)
            } else {
                received(error: .authenticationProviderError(error))
            }
            
            return
        }
        
        guard let url = url else {
            received(error: .genericError(message: "Authentication session returned neither a URL or an error"))
            return
        }
        
        do {
            try flow.resume(with: url)
        } catch {
            received(error: .authenticationProviderError(error))
        }
    }
    
    func received(token: Token) {
        guard let delegate = delegate else { return }
        
        delegate.authentication(provider: self, received: token)
    }
    
    func received(error: WebAuthenticationError) {
        guard let delegate = delegate else { return }
        
        delegate.authentication(provider: self, received: error)
    }
    
    func cancel() {
        authenticationSession?.cancel()
        authenticationSession = nil
    }
}

@available(iOS, introduced: 11.0, deprecated: 12.0)
extension SafariServicesProvider: AuthorizationCodeFlowDelegate {
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL) where Flow : AuthorizationCodeFlow {
        authenticate(using: url)
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        received(error: .oauth2(error: error))
    }
    
    func authentication<Flow>(flow: Flow, received token: Token) {
        received(token: token)
    }
}
#endif
