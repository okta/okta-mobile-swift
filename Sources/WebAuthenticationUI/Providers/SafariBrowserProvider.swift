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
import SafariServices

@available(iOS, introduced: 9.0, deprecated: 11.0)
class SafariBrowserProvider: NSObject, WebAuthenticationProvider {
    let flow: AuthorizationCodeFlow
    let delegate: WebAuthenticationProviderDelegate
    
    var canStart: Bool {
        safariController != nil
    }
    
    private var safariController: SFSafariViewController?
    private let anchor: WebAuthentication.WindowAnchor?
    
    init(flow: AuthorizationCodeFlow,
         window: WebAuthentication.WindowAnchor?,
         delegate: WebAuthenticationProviderDelegate)
    {
        self.flow = flow
        self.window = window
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
            if let presentedViewController = self.window?.rootViewController?.presentedViewController {
                presentedViewController.present(safariController, animated: true)
            } else if let rootViewController = self.window?.rootViewController {
                rootViewController.present(safariController, animated: true)
            }
        }
    }
    
    func received(token: Token) {
        delegate.authentication(provider: self, received: token)
    }
    
    func received(error: WebAuthenticationError) {
        delegate.authentication(provider: self, received: error)
    }
    
    func process(url: URL?) {
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
