/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension ClientConfiguration {
    var idxConfiguration: IDXClient.Configuration {
        return IDXClient.Configuration(issuer: issuer,
                                       clientId: clientId,
                                       clientSecret: nil,
                                       scopes: ["openid", "profile", "offline_access"],
                                       redirectUri: redirectUri)
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var issuerField: UITextField!
    @IBOutlet weak var clientIdField: UITextField!
    @IBOutlet weak var redirectField: UITextField!
    private var signin: Signin?
    var configuration: ClientConfiguration? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configuration = ClientConfiguration.launchConfiguration ?? ClientConfiguration.userDefaults
        issuerField.text = configuration?.issuer
        clientIdField.text = configuration?.clientId
        redirectField.text = configuration?.redirectUri
        
        issuerField.accessibilityIdentifier = "issuerField"
        clientIdField.accessibilityIdentifier = "clientIdField"
        redirectField.accessibilityIdentifier = "redirectField"
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped)))
    }
    
    @objc func backgroundTapped() {
        view.endEditing(true)
    }
    
    func loginComplete(with token: IDXClient.Token) {
        print("Authenticated with \(token)")
    }

    @IBAction func logIn(_ sender: Any) {
        guard let issuerUrl = issuerField.text,
              let clientId = clientIdField.text,
              let redirectUri = redirectField.text else
        {
            let alert = UIAlertController(title: "Invalid configuration",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        configuration = ClientConfiguration(clientId: clientId,
                                            issuer: issuerUrl,
                                            redirectUri: redirectUri,
                                            shouldSave: true)
        configuration?.save()
        
        guard let config = configuration?.idxConfiguration else {
            return
        }
        
        signin = Signin(using: config)
        signin?.signin(from: self) { [weak self] (token, error) in
            if let error = error {
                print("Could not sign in: \(error)")
            } else {
                guard let controller = self?.storyboard?.instantiateViewController(identifier: "TokenResult") as? TokenResultViewController else { return }
                controller.token = token
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    @IBAction func dumpRequestLog(_ sender: Any) {
        print(URLSessionAudit.shared)
    }

    @IBAction func resetRequestLog(_ sender: Any) {
        URLSessionAudit.shared.reset()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case issuerField:
            clientIdField.becomeFirstResponder()
        case clientIdField:
            redirectField.becomeFirstResponder()
        case redirectField:
            redirectField.resignFirstResponder()
            logIn(redirectField as Any)
            
        default: break
        }
        return false
    }
}
