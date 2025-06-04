/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OktaIdx

class SigninCoordinator {
    static let shared = SigninCoordinator()
    
    struct UserDefaultsKeys {
        static let storedTokenKey = "com.okta.directAuth.storedToken"
    }
    
    weak var windowScene: UIWindowScene?
    private(set) var onboardingWindow: UIWindow?
    
    init() {
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged, object: nil, queue: .main) { (note) in
            let credential = note.object as? Credential
            
            if credential == nil {
                self.show()
            } else {
                self.dismiss()
            }
        }
    }
    
    func show(in scene: UIWindowScene? = nil) {
        guard let windowScene = scene ?? self.windowScene,
              onboardingWindow == nil
        else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootViewController = storyboard.instantiateViewController(identifier: "LandingNavigationController") as? UINavigationController
        else {
            return
        }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        onboardingWindow = window
    }
    
    func dismiss(animated: Bool = true) {
        guard let onboardingWindow = onboardingWindow else { return }
        if animated {
            UIView.animate(withDuration: 0.33) {
                onboardingWindow.alpha = 0
            } completion: { _ in
                self.onboardingWindow = nil
            }
        } else {
            self.onboardingWindow = nil
        }
    }
    
    /// Digs through the view hierarchy to find the current sign-in controller, if present.
    private var signInViewController: (UIViewController & IDXSigninController)? {
        guard var viewController = onboardingWindow?.rootViewController else {
            return nil
        }

        while !(viewController is IDXSigninController) {
            if let navigationContoller = viewController as? UINavigationController,
               let topController = navigationContoller.topViewController
            {
                viewController = topController
            }
            
            else if let presentedController = viewController.presentedViewController {
                viewController = presentedController
            }
        }
        
        return viewController as? (UIViewController & IDXSigninController)
    }
    
    /// Handles an inbound email magic link.
    func handle(magicLink url: URL) {
        signInViewController?.signin?.authorize(magicLink: url)
    }
}
