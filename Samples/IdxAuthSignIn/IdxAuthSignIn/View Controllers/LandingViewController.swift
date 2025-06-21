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
import OktaIdxAuth

class LandingViewController: UIViewController {
    @IBOutlet weak private(set) var signInButtonStackView: UIStackView!
    @IBOutlet weak private(set) var signInButton: SigninButton!
    @IBOutlet weak private(set) var footerView: UIView!
    @IBOutlet weak var configurationInfoLabel: UILabel!
    private var signin: Signin?

    var isSignInAvailable: Bool = false {
        didSet {
            signInButton.isEnabled = isSignInAvailable
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let configuration = ClientConfiguration.active {
            configurationUpdated(configuration.flow)
        }
        
        NotificationCenter.default.addObserver(forName: .configurationChanged, object: nil, queue: .main) { (note) in
            self.configurationUpdated(note.object as? InteractionCodeFlow)
        }
        
        if !isSignInAvailable {
            performSegue(withIdentifier: "ConfigureSegue", sender: nil)
        }
    }
    
    func configurationUpdated(_ flow: InteractionCodeFlow?) {
        isSignInAvailable = flow != nil
        if let configuration = flow {
            configurationInfoLabel.text = """
            Client ID: \(configuration.client.configuration.clientId)
            """
            signin = Signin(using: configuration)
        } else {
            configurationInfoLabel.text = "Please configure your client"
            signin = nil
        }
    }
    
    @IBAction func debugAction(_ sender: Any) {
        let actionsheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionsheet.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem

        #if DEBUG
        let observer = DebugAPIRequestObserver.shared
        var title: String
        if observer.observeAllOAuth2Clients {
            title = "Stop logging to console"
        } else {
            title = "Start logging to console"
        }
        actionsheet.addAction(.init(title: title, style: .default, handler: { _ in
            observer.observeAllOAuth2Clients = !observer.observeAllOAuth2Clients
            guard let client = self.signin?.flow.client else { return }

            if observer.observeAllOAuth2Clients {
                observer.startObserving(client: client)
            } else {
                observer.stopObserving(client: client)
            }
        }))
        #endif

        actionsheet.addAction(.init(title: "Cancel", style: .cancel))
        
        present(actionsheet, animated: true)
    }
    
    @IBAction func logIn(_ sender: Any) {
        guard let signin = signin else {
            return
        }
        
        signin.signin(from: self) { result in
            switch result {
            case .failure(let error):
                print("Could not sign in: \(error.localizedDescription)")
            case .success(let credential):
                Credential.default = credential
            }
        }
    }
}
