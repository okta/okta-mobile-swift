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
final class SafariServicesProvider: NSObject, WebAuthenticationProvider {
    let loginFlow: AuthorizationCodeFlow
    let logoutFlow: SessionLogoutFlow?
    private(set) weak var delegate: WebAuthenticationProviderDelegate?
    
    private(set) var authenticationSession: SFAuthenticationSession?
    
    init(loginFlow: AuthorizationCodeFlow,
         logoutFlow: SessionLogoutFlow?,
         delegate: WebAuthenticationProviderDelegate)
    {
        self.loginFlow = loginFlow
        self.logoutFlow = logoutFlow
        self.delegate = delegate
        
        super.init()
        
        self.loginFlow.add(delegate: self)
        self.logoutFlow?.add(delegate: self)
    }
    
    deinit {
        self.loginFlow.remove(delegate: self)
        self.logoutFlow?.remove(delegate: self)
    }
    
    func start(context: AuthorizationCodeFlow.Context?, additionalParameters: [String: String]?) {
        loginFlow.start(with: context, additionalParameters: additionalParameters) { _ in }
    }
    
    func logout(context: SessionLogoutFlow.Context, additionalParameters: [String: String]?) {
        // LogoutFlow invokes delegate, so an error is propagated from delegate method
        try? logoutFlow?.start(with: context, additionalParameters: additionalParameters) { _ in }
    }
    
    func authenticate(using url: URL) {
        authenticationSession = SFAuthenticationSession(
            url: url,
            callbackURLScheme: loginFlow.redirectUri.scheme,
            completionHandler: { [weak self] url, error in
                self?.process(url: url, error: error)
            })
        
        authenticationSession?.start()
    }
    
    func logout(using url: URL) {
        guard let logoutFlow = logoutFlow else {
            return
        }

        authenticationSession = SFAuthenticationSession(
            url: url,
            callbackURLScheme: logoutFlow.logoutRedirectUri.scheme,
            completionHandler: { [weak self] url, error in
                self?.processLogout(url: url, error: error)
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
            } else if let url = url,
                      let serverError = try? url.oauth2ServerError(redirectUri: loginFlow.redirectUri)
            {
                received(error: .serverError(serverError))
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
            try loginFlow.resume(with: url) { _ in }
        } catch {
            received(error: .authenticationProviderError(error))
        }
    }
    
    func processLogout(url: URL?, error: Error?) {
        guard let delegate = delegate else { return }

        if let error = error {
            let nsError = error as NSError
            if nsError.domain == SFAuthenticationErrorDomain,
               nsError.code == SFAuthenticationError.canceledLogin.rawValue
            {
                received(logoutError: .userCancelledLogin)
            } else if let url = url,
                      let serverError = try? url.oauth2ServerError(redirectUri: logoutFlow?.logoutRedirectUri)
            {
                received(logoutError: .serverError(serverError))
            } else {
                received(logoutError: .authenticationProviderError(error))
            }
            
            return
        }
        
        guard url != nil else {
            received(logoutError: .genericError(message: "Authentication session returned neither a URL or an error on logout"))
            return
        }
        
        delegate.logout(provider: self, finished: true)
    }
    
    func received(token: Token) {
        guard let delegate = delegate else { return }
        
        delegate.authentication(provider: self, received: token)
    }
    
    func received(error: WebAuthenticationError) {
        guard let delegate = delegate else { return }
        
        delegate.authentication(provider: self, received: error)
    }
    
    func received(logoutError: WebAuthenticationError) {
        guard let delegate = delegate else { return }

        delegate.logout(provider: self, received: logoutError)
    }
    
    func cancel() {
        authenticationSession?.cancel()
        authenticationSession = nil
    }
}

@available(iOS, introduced: 11.0, deprecated: 12.0)
extension SafariServicesProvider: AuthorizationCodeFlowDelegate {
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL) where Flow: AuthorizationCodeFlow {
        authenticate(using: url)
    }
    
    func authentication<Flow>(flow: Flow, received error: OAuth2Error) {
        received(error: .oauth2(error: error))
    }
    
    func authentication<Flow>(flow: Flow, received token: Token) {
        received(token: token)
    }
}

@available(iOS, introduced: 11.0, deprecated: 12.0)
extension SafariServicesProvider: SessionLogoutFlowDelegate {
    func logout<Flow>(flow: Flow, shouldLogoutUsing url: URL) where Flow: SessionLogoutFlow {
        logout(using: url)
    }
    
    func logout<SessionLogoutFlow>(flow: SessionLogoutFlow, received error: OAuth2Error) {
        received(logoutError: .oauth2(error: error))
    }
}
#endif
