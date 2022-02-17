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

import AuthFoundation
import OktaOAuth2

#if canImport(AuthenticationServices)
import AuthenticationServices

@available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *)
class AuthenticationServicesProvider: NSObject, WebAuthenticationProvider {
    let flow: AuthorizationCodeFlow
    private(set) weak var delegate: WebAuthenticationProviderDelegate?
    private(set) var authenticationSession: ASWebAuthenticationSession?

    private let anchor: ASPresentationAnchor?
    
    init(flow: AuthorizationCodeFlow,
         from window: WebAuthentication.WindowAnchor?,
         delegate: WebAuthenticationProviderDelegate) 
    {
        self.flow = flow
        self.anchor = window
        self.delegate = delegate
        
        super.init()
        
        self.flow.add(delegate: self)
    }
    
    deinit {
        self.flow.remove(delegate: self)
    }

    func start(context: AuthorizationCodeFlow.Context? = nil) {
        guard let delegate = delegate else { return }
        
        do {
            try flow.resume(with: context)
        } catch {
            delegate.authentication(provider: self, received: error)
        }
    }
    
    func authenticate(using url: URL) {
        guard let delegate = delegate else { return }
        
        authenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: flow.callbackScheme,
            completionHandler: { url, error in
                self.process(url: url, error: error)
            })
        
        if #available(iOS 13.0, *) {
            authenticationSession?.prefersEphemeralWebBrowserSession = delegate.authenticationShouldUseEphemeralSession(provider: self)
            authenticationSession?.presentationContextProvider = self
        }

        DispatchQueue.main.async {
            self.authenticationSession?.start()
        }
    }
    
    func cancel() {
        authenticationSession?.cancel()
        authenticationSession = nil
    }
    
    func received(token: Token) {
        guard let delegate = delegate else { return }
        
        delegate.authentication(provider: self, received: token)
    }
    
    func received(error: WebAuthenticationError) {
        guard let delegate = delegate else { return }
        
        delegate.authentication(provider: self, received: error)
    }
    
    func process(url: URL?, error: Error?) {
        defer { authenticationSession = nil }
        
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == ASWebAuthenticationSessionErrorDomain,
               nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
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
}

@available(iOS 12.0, macOS 10.15, *)
extension AuthenticationServicesProvider: AuthenticationDelegate, AuthorizationCodeFlowDelegate {
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL) where Flow : AuthorizationCodeFlow {
        authenticate(using: url)
    }
    
    func authentication<AuthorizationCodeFlow>(flow: AuthorizationCodeFlow, received token: Token) {
        received(token: token)
    }
    
    func authentication<AuthorizationCodeFlow>(flow: AuthorizationCodeFlow, received error: OAuth2Error) {
        received(error: .oauth2(error: error))
    }
}
    
@available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *)
extension AuthenticationServicesProvider: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let anchor = anchor {
            return anchor
        }
        
        #if os(macOS)
        return NSWindow()
        #else
        return UIWindow()
        #endif
    }
}
#endif
