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

#if os(iOS)

import Foundation
import OktaOAuth2
import SafariServices

@available(iOS, introduced: 9.0, deprecated: 11.0)
final class SafariBrowserProvider: NSObject, WebAuthenticationProvider {
    let loginFlow: AuthorizationCodeFlow
    let logoutFlow: SessionLogoutFlow?
    private(set) weak var delegate: WebAuthenticationProviderDelegate?
    
    private(set) var safariController: SFSafariViewController?
    private let anchor: WebAuthentication.WindowAnchor?
    
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
    
    func authenticate(using url: URL) {
        safariController = SFSafariViewController(url: url)
        
        guard let safariController = safariController else { return }
        
        DispatchQueue.main.async {
            UIWindow
                .topViewController(from: self.anchor?.rootViewController)?
                .present(safariController, animated: true)
        }
    }
    
    func logout(using url: URL) {
        // The process is the same as for authentication
        authenticate(using: url)
    }
    
    func received(token: Token) {
        defer { safariController = nil }
        
        guard let delegate = delegate else { return }
        delegate.authentication(provider: self, received: token)
    }
    
    func received(error: WebAuthenticationError) {
        defer { safariController = nil }

        guard let delegate = delegate else { return }
        delegate.authentication(provider: self, received: error)
    }
    
    func received(logoutError: WebAuthenticationError) {
        delegate?.authentication(provider: self, received: logoutError)
    }
    
    func start(context: AuthorizationCodeFlow.Context?, additionalParameters: [String: String]?) {
        loginFlow.start(with: context, additionalParameters: additionalParameters) { _ in }
    }
    
    func logout(context: SessionLogoutFlow.Context, additionalParameters: [String: String]?) {
        guard let logoutFlow = logoutFlow else {
            return
        }

        // LogoutFlow invokes delegate, so an error is propagated from delegate method
        try? logoutFlow.start(with: context, additionalParameters: additionalParameters) { _ in }
    }
    
    func cancel() {
        safariController?.dismiss(animated: true)
        safariController = nil
    }
}

@available(iOS, introduced: 9.0, deprecated: 11.0)
extension SafariBrowserProvider: AuthorizationCodeFlowDelegate {
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

@available(iOS, introduced: 9.0, deprecated: 11.0)
extension SafariBrowserProvider: SessionLogoutFlowDelegate {
    func logout<Flow>(flow: Flow, shouldLogoutUsing url: URL) where Flow: SessionLogoutFlow {
        logout(using: url)
    }
    
    func logout<SessionLogoutFlow>(flow: SessionLogoutFlow, received error: OAuth2Error) {
        received(logoutError: .oauth2(error: error))
    }
}

private extension UIWindow {
    static func topViewController(from rootViewController: UIViewController?) -> UIViewController? {
        if let navigationController = rootViewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = rootViewController as? UITabBarController,
            let selected = tabBarController.selectedViewController {
            return topViewController(from: selected)
        }

        if let presentedViewController = rootViewController?.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return rootViewController
    }
}
#endif
