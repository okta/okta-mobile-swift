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
class SafariBrowserProvider: NSObject, WebAuthenticationProvider {
    let flow: AuthorizationCodeFlow
    let delegate: WebAuthenticationProviderDelegate
    
    private(set) var safariController: SFSafariViewController?
    private let anchor: WebAuthentication.WindowAnchor?
    
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
    
    func authenticate(using url: URL) {
        safariController = SFSafariViewController(url: url)
        
        guard let safariController = safariController else { return }
        
        DispatchQueue.main.async {
            UIWindow
                .topViewController(from: self.anchor?.rootViewController)?
                .present(safariController, animated: true)
        }
    }
    
    func received(token: Token) {
        delegate.authentication(provider: self, received: token)
    }
    
    func received(error: WebAuthenticationError) {
        delegate.authentication(provider: self, received: error)
    }
    
    func start(context: AuthorizationCodeFlow.Context?) {
        do {
            try flow.resume(with: context)
        } catch {
            delegate.authentication(provider: self, received: error)
        }
    }
    
    func cancel() {
        safariController?.dismiss(animated: true)
    }
}

@available(iOS, introduced: 9.0, deprecated: 11.0)
extension SafariBrowserProvider: AuthorizationCodeFlowDelegate {
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
