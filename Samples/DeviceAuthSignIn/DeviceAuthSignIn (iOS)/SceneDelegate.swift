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

import UIKit
import AuthFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    weak var windowScene: UIWindowScene?
    weak var signInViewController: UIViewController?

    func signIn() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signInController = storyboard.instantiateInitialViewController()
        
        signInViewController = signInController
        window?.rootViewController = signInController
    }

    func showProfile() {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let profileViewController = storyboard.instantiateInitialViewController()
        
        window?.rootViewController = profileViewController
    }
    
    func setRootViewController() {
        if Credential.default == nil {
            self.signIn()
        } else {
            self.showProfile()
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        windowScene = scene
        
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged, object: nil, queue: .main) { _ in
            self.setRootViewController()
        }
        
        setRootViewController()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard signInViewController == nil,
              Credential.default == nil
        else {
            return
        }
        
        DispatchQueue.main.async {
            self.signIn()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
