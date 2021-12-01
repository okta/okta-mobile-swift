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

class ViewController: UIViewController {

    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var clientIdLabel: UILabel!

    let auth: WebAuthentication? = {
        try? WebAuthentication()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clientIdLabel.text = auth?.flow.configuration.clientId ?? "Not configured"
    }
    
    @IBAction func ephemeralSwitchChanged(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        auth?.ephemeralSession = sender.isOn
    }
    
    @MainActor
    func signInAsync() async {
        let window = viewIfLoaded?.window
        do {
            let token = try await WebAuthentication.signIn(from: window)
            
            let alert = UIAlertController(title: "Signed in!", message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            present(alert, animated: true)
        } catch {
            let alert = UIAlertController(title: "Cannot sign in", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            present(alert, animated: true)
        }
    }
    
    @IBAction func signIn(_ sender: Any) {
        Task {
            await signInAsync()
        }
        return
        
//        auth?.start(from: viewIfLoaded?.window) { result in
//            switch result {
//            case .success(let token):
//                print(token)
//                let alert = UIAlertController(title: "Signed in!", message: nil, preferredStyle: .alert)
//                alert.addAction(.init(title: "OK", style: .default))
//                
//                self.present(alert, animated: true)
//            case .failure(let error):
//                let alert = UIAlertController(title: "Cannot sign in", message: error.localizedDescription, preferredStyle: .alert)
//                alert.addAction(.init(title: "OK", style: .default))
//                
//                self.present(alert, animated: true)
//            }
//        }
    }
}
