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

import UIKit
import AuthFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    weak var windowScene: UIWindowScene?
    
    func showSignIn() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let signInController = storyboard.instantiateInitialViewController() else { return }
        
        if let rootViewController = window?.rootViewController,
           type(of: rootViewController.self) == type(of: signInController.self) {
            print("[WARN] Try to set the same type of controller.")
            return
        }
        
        window?.rootViewController = signInController
    }
    
    func showProfile() {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        guard let profileViewController = storyboard.instantiateInitialViewController() else { return }
        
        // Avoid resetting if such happens
        if let rootViewController = window?.rootViewController,
           type(of: rootViewController.self) == type(of: profileViewController.self) {
            print("[WARN] Try to set the same type of controller.")
            return
        }
        
        window?.rootViewController = profileViewController
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        windowScene = scene
        
        if Credential.default == nil {
            showSignIn()
        } else {
            showProfile()
        }
        
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged, object: nil, queue: .main) { notification in
            if notification.object == nil {
                self.showSignIn()
            } else {
                self.showProfile()
            }
        }
    }
}
