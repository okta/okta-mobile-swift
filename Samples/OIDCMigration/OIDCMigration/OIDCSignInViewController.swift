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
import OktaOidc
import AuthFoundation

class OIDCSignInViewController: UIViewController {
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var clientIdLabel: UILabel!
    @IBOutlet weak var migrateButton: UIButton!
    @IBOutlet weak var openUserProfileButton: UIButton!
    
    var oktaOidc: OktaOidc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUIState()
        
        // Dismiss the profile view controller when it is signed out
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dismissProfile),
                                               name: .defaultCredentialChanged,
                                               object: nil)
    }
    
    @objc
    func dismissProfile() {
        guard presentedViewController != nil else { return }
        
        self.presentedViewController?.dismiss(animated: true, completion: {
            self.updateUIState()
        })
    }
    
    func updateUIState() {
        if let client = try? OktaOidc() {
            oktaOidc = client
            clientIdLabel.text = client.configuration.clientId
            
            if OktaOidcStateManager.readFromSecureStorage(for: client.configuration) != nil {
                signInButton.isHidden = true
                signOutButton.isHidden = false
            } else {
                signInButton.isHidden = false
                signOutButton.isHidden = true
            }
        } else {
            clientIdLabel.text = "Not configured"
            signInButton.isEnabled = false
            signOutButton.isHidden = true
        }
        
        if Credential.default == nil {
            migrateButton.isEnabled = SDKVersion.isMigrationNeeded
            migrateButton.isHidden = false
            openUserProfileButton.isHidden = true
        } else {
            migrateButton.isHidden = true
            openUserProfileButton.isHidden = false
        }
    }

    @IBAction func ephemeralSwitchChanged(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        oktaOidc?.configuration.noSSO = sender.isOn
    }
    
    func show(error: Error) {
        // There's currently no way to know when the ASWebAuthenticationSession will be dismissed,
        // so to ensure the alert can be displayed, we must delay presenting an error until the
        // dismissal is complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
            let alert = UIAlertController(title: "Cannot sign in",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }

    @IBAction func signIn(_ sender: Any) {
        oktaOidc?.signInWithBrowser(from: self, callback: { stateManager, error in
            if let error = error {
                self.show(error: error)
            }

            guard let stateManager = stateManager else {
                return
            }

            stateManager.writeToSecureStorage()

            self.updateUIState()
        })
    }
    
    @IBAction func signOut(_ sender: Any) {
        guard let config = oktaOidc?.configuration,
              let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        else {
            return
        }

        oktaOidc?.signOutOfOkta(stateManager, from: self, callback: { _ in
            try? stateManager.removeFromSecureStorage()
            self.updateUIState()
        })
    }
    
    @IBAction func migrateAction(_ sender: Any) {
        do {
            try SDKVersion.migrateIfNeeded()
            self.updateUIState()
        } catch {
            show(error: error)
        }
    }
    
    @IBAction func openUserProfile(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        guard let profileViewController = storyboard.instantiateInitialViewController() else {
            return
        }

        present(profileViewController, animated: true)
    }
}
