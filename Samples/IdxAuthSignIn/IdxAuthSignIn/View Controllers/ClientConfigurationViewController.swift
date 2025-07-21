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
import OktaIdxAuth

class ClientConfigurationViewController: UIViewController {
    @IBOutlet weak var recoveryTokenField: UITextField!
    var configuration: ClientConfiguration? = ClientConfiguration.active
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recoveryTokenField.text = configuration?.recoveryToken
        recoveryTokenField.accessibilityIdentifier = "recoveryTokenField"

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped)))
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        ClientConfiguration.active = ClientConfiguration(recoveryToken: recoveryTokenField.text)
        dismiss(animated: true)
    }
    
    @objc func backgroundTapped() {
        view.endEditing(true)
    }
}

extension ClientConfigurationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
