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
protocol AuthenticationServicesProviderSession {
    init(url URL: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler)

    @available(iOS 13.0, macOS 10.15, *)
    var presentationContextProvider: ASWebAuthenticationPresentationContextProviding? { get set }

    @available(iOS 13.0, macOS 10.15, *)
    var prefersEphemeralWebBrowserSession: Bool { get set }

    @available(iOS 13.4, macCatalyst 13.4, macOS 10.15.4, *)
    var canStart: Bool { get }

    func start() -> Bool

    func cancel()
}

@available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *)
extension ASWebAuthenticationSession: AuthenticationServicesProviderSession {}

@available(iOS 12.0, macOS 10.15, macCatalyst 13.0, *)
class AuthenticationServicesProvider: NSObject, WebAuthenticationProvider {
    let loginFlow: AuthorizationCodeFlow
    let logoutFlow: SessionLogoutFlow?
    private(set) weak var delegate: WebAuthenticationProviderDelegate?
    private(set) var authenticationSession: AuthenticationServicesProviderSession?

    private let anchor: ASPresentationAnchor?
    
    init(loginFlow: AuthorizationCodeFlow,
         logoutFlow: SessionLogoutFlow?,
         from window: WebAuthentication.WindowAnchor?,
         delegate: WebAuthenticationProviderDelegate)
    {
        self.loginFlow = loginFlow
        self.logoutFlow = logoutFlow
        self.anchor = window
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
    
    func createSession(url: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) -> AuthenticationServicesProviderSession {
        ASWebAuthenticationSession(url: url,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler)
    }
    
    func authenticate(using url: URL) {
        guard let delegate = delegate else { return }
        
        authenticationSession = createSession(
            url: url,
            callbackURLScheme: loginFlow.redirectUri.scheme,
            completionHandler: { url, error in
                self.process(url: url, error: error)
            })
        
        if #available(iOS 13.0, macCatalyst 13.0, *) {
            authenticationSession?.prefersEphemeralWebBrowserSession = delegate.authenticationShouldUseEphemeralSession(provider: self)
            authenticationSession?.presentationContextProvider = self
        }

        DispatchQueue.main.async {
            _ = self.authenticationSession?.start()
        }
    }
    
    func logout(context: SessionLogoutFlow.Context, additionalParameters: [String: String]?) {
        guard let logoutFlow = logoutFlow else {
            return
        }

        // LogoutFlow invokes delegate, so an error is propagated from delegate method
        try? logoutFlow.start(with: context, additionalParameters: additionalParameters) { _ in }
    }
    
    func logout(using url: URL) {
        guard let logoutFlow = logoutFlow else {
            return
        }

        authenticationSession = createSession(url: url,
                                              callbackURLScheme: logoutFlow.logoutRedirectUri.scheme,
                                              completionHandler: { url, error in
            self.processLogout(url: url, error: error)
        })
        
        if #available(iOS 13.0, *) {
            if let delegate = delegate {
                authenticationSession?.prefersEphemeralWebBrowserSession = delegate.authenticationShouldUseEphemeralSession(provider: self)
            }
            authenticationSession?.presentationContextProvider = self
        }

        DispatchQueue.main.async {
            _ = self.authenticationSession?.start()
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
    
    func received(logoutError: WebAuthenticationError) {
        guard let delegate = delegate else { return }
        
        delegate.logout(provider: self, received: logoutError)
    }
    
    func process(url: URL?, error: Error?) {
        defer { authenticationSession = nil }
        
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == ASWebAuthenticationSessionErrorDomain,
               nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
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
        defer { authenticationSession = nil }

        guard let delegate = delegate else { return }
        
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == ASWebAuthenticationSessionErrorDomain,
               nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue
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
}

@available(iOS 12.0, macOS 10.15, *)
extension AuthenticationServicesProvider: AuthenticationDelegate, AuthorizationCodeFlowDelegate {
    func authentication<Flow>(flow: Flow, shouldAuthenticateUsing url: URL) where Flow: AuthorizationCodeFlow {
        authenticate(using: url)
    }
    
    func authentication<AuthorizationCodeFlow>(flow: AuthorizationCodeFlow, received token: Token) {
        received(token: token)
    }
    
    func authentication<AuthorizationCodeFlow>(flow: AuthorizationCodeFlow, received error: OAuth2Error) {
        received(error: .oauth2(error: error))
    }
}

@available(iOS 12.0, macOS 10.15, *)
extension AuthenticationServicesProvider: SessionLogoutFlowDelegate {
    func logout<Flow>(flow: Flow, shouldLogoutUsing url: URL) where Flow: SessionLogoutFlow {
        logout(using: url)
    }
    
    func logout<SessionLogoutFlow>(flow: SessionLogoutFlow, received error: OAuth2Error) {
        received(logoutError: .oauth2(error: error))
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
