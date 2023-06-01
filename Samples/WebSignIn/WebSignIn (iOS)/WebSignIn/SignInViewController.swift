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
import WebAuthenticationUI

class SignInViewController: UIViewController {
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInWithRefreshButton: UIButton!
    @IBOutlet weak var ephemeralSwitch: UISwitch!
    @IBOutlet weak var clientIdLabel: UILabel!

    let auth = WebAuthentication.shared
    let options: [WebAuthentication.Option]? = [
        // .login(hint: "jane.doe@example.com"),
        // .prompt(.login)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let clientId = auth?.signInFlow.client.configuration.clientId {
            clientIdLabel.text = clientId
        } else {
            clientIdLabel.text = "Not configured"
            signInButton.isEnabled = false
            signInWithRefreshButton.isEnabled = false
            ephemeralSwitch.isEnabled = false
        }
    }
    
    @IBAction func ephemeralSwitchChanged(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        auth?.ephemeralSession = sender.isOn
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
        let window = viewIfLoaded?.window
        auth?.signIn(from: window, options: options) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(token)
                    
                    // This saves the device secret in a place accessible by the SingleSignOn sample application.
                    try Keychain.saveDeviceSSO(token)
                } catch {
                    self.show(error: error)
                    return
                }
                                        
                self.dismiss(animated: true)
            case .failure(let error):
                self.show(error: error)
            }
        }
    }
    
    @IBAction func signInWithRefreshToken(_ sender: Any) {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasStrings,
           let pasteStrings = pasteboard.strings
        {
            for string in pasteStrings {
                var matchString = string.unicodeScalars
                matchString.removeAll(where: CharacterSet.alphanumerics.contains)
                if matchString.isEmpty {
                    signInWith(refreshToken: string)
                    return
                }
            }
        }
        
        let alert = UIAlertController(title: "Sign In with Refresh Token",
                                      message: "Enter the refresh token below",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "refresh_token"
            field.autocorrectionType = .no
        }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "OK", style: .default) { _ in
            guard let textField = alert.textFields?.first,
                let string = textField.text,
                !string.isEmpty
            else {
                alert.dismiss(animated: true) {
                    let alert = UIAlertController(title: "Invalid refresh token",
                                                  message: nil,
                                                  preferredStyle: .alert)
                    alert.addAction(.init(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
                return
            }
            
            self.signInWith(refreshToken: string)
        })
        present(alert, animated: true)
    }
    
    func signInWith(refreshToken: String) {
        guard let client = auth?.signInFlow.client else { return }
        
        Token.from(refreshToken: refreshToken, using: client) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    do {
                        try Credential.store(token)
                        
                        // This saves the device secret in a place accessible by the SingleSignOn sample application.
                        try Keychain.saveDeviceSSO(token)
                    } catch {
                        self.show(error: error)
                    }
                case .failure(let error):
                    self.show(error: error)
                }
            }
        }
    }
}
