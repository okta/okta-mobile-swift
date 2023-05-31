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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    weak var signInViewController: UIViewController?

    func signIn() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signInController = storyboard.instantiateViewController(withIdentifier: "SignIn")
        
        signInViewController = signInController
        window?.rootViewController = signInController
    }

    func showProfile() {
        let storyboard = UIStoryboard(name: "Profile-tvOS", bundle: nil)
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("--reset-keychain") {
            try? Keychain.Search().delete()
        }
        
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged, object: nil, queue: .main) { _ in
            self.setRootViewController()
        }
        
        setRootViewController()
         
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard signInViewController == nil,
              Credential.default == nil
        else {
            return
        }
        
        DispatchQueue.main.async {
            self.signIn()
        }
    }
}
