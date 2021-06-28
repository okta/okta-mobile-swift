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

extension ClientConfiguration {
    var idxConfiguration: IDXClient.Configuration {
        return IDXClient.Configuration(issuer: issuer,
                                       clientId: clientId,
                                       clientSecret: nil,
                                       scopes: scopes.components(separatedBy: .whitespaces),
                                       redirectUri: redirectUri)
    }
}

class ClientConfigurationViewController: UIViewController {
    @IBOutlet weak var issuerField: UITextField!
    @IBOutlet weak var clientIdField: UITextField!
    @IBOutlet weak var scopesField: UITextField!
    @IBOutlet weak var redirectField: UITextField!
    var configuration: ClientConfiguration? = ClientConfiguration.active
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        issuerField.text = configuration?.issuer
        clientIdField.text = configuration?.clientId
        scopesField.text = configuration?.scopes
        redirectField.text = configuration?.redirectUri
        
        issuerField.accessibilityIdentifier = "issuerField"
        clientIdField.accessibilityIdentifier = "clientIdField"
        scopesField.accessibilityIdentifier = "scopesField"
        redirectField.accessibilityIdentifier = "redirectField"
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped)))
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        guard let issuerUrl = issuerField.text,
              let clientId = clientIdField.text,
              let scopes = scopesField.text,
              let redirectUri = redirectField.text else
        {
            let alert = UIAlertController(title: "Invalid configuration",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        do {
            configuration = try ClientConfiguration(clientId: clientId,
                                                    issuer: issuerUrl,
                                                    redirectUri: redirectUri,
                                                    scopes: scopes,
                                                    shouldSave: true)
            configuration?.save()
            dismiss(animated: true)
        } catch {
            let alert = UIAlertController(title: "Configuration error",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc func backgroundTapped() {
        view.endEditing(true)
    }
}

extension ClientConfigurationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case issuerField:
            clientIdField.becomeFirstResponder()
        case clientIdField:
            scopesField.becomeFirstResponder()
        case scopesField:
            redirectField.becomeFirstResponder()
        case redirectField:
            redirectField.resignFirstResponder()
            
        default: break
        }
        return false
    }
}
