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
import OktaOAuth2
import OktaAuthNative

class SignInViewController: UIViewController, UITextFieldDelegate {
    enum State {
        case normal, canSignIn, isSigningIn, notConfigured
    }
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var clientIdLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let config = try? OAuth2Client.PropertyListConfiguration()
    
    var state: State = .normal {
        didSet {
            switch state {
            case .notConfigured:
                usernameField.isEnabled = false
                passwordField.isEnabled = false
                signInButton.isEnabled = false
                activityIndicator.stopAnimating()
            case .normal:
                usernameField.isEnabled = true
                passwordField.isEnabled = true
                signInButton.isEnabled = false
                activityIndicator.stopAnimating()
            case .canSignIn:
                usernameField.isEnabled = true
                passwordField.isEnabled = true
                signInButton.isEnabled = true
                activityIndicator.stopAnimating()
            case .isSigningIn:
                usernameField.isEnabled = false
                passwordField.isEnabled = false
                signInButton.isEnabled = false
                activityIndicator.startAnimating()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let clientId = config?.clientId {
            clientIdLabel.text = clientId
        } else {
            clientIdLabel.text = "Not configured"
            state = .notConfigured
        }
    }

    @IBAction func signIn(_ sender: Any) {
        state = .isSigningIn
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
              let textRange = Range(range, in: textFieldText)
        else {
            return true
        }
        
        let text = textFieldText.replacingCharacters(in: textRange, with: string)
        if text.isEmpty ||
            (textField === usernameField && passwordField.text?.isEmpty ?? false) ||
            (textField === passwordField && usernameField.text?.isEmpty ?? false)
        {
            state = .normal
        } else {
            state = .canSignIn
        }
        
        return true
    }
}

