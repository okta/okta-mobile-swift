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

import OktaOAuth2
import UIKit

final class SingleSignOnViewController: UIViewController {
    @IBOutlet private weak var signInButton: UIButton!
    @IBOutlet private weak var clientIdLabel: UILabel!
    @IBOutlet private weak var indicatorView: UIView!
    
    private var deviceToken: String? {
        try? Keychain.get(.deviceSecret)
    }
    
    private var idToken: String? {
        try? Keychain.get(.idToken)
    }
    
    lazy var domain: String = {
         ProcessInfo.processInfo.environment["E2E_DOMAIN"] ?? "<#domain#>"
     }()

     lazy var clientId: String = {
         ProcessInfo.processInfo.environment["E2E_CLIENT_ID"] ?? "<#client_id#>"
     }()
    
    private lazy var flow: TokenExchangeFlow? = {
        guard !domain.isEmpty,
              let issuerUrl = URL(string: "https://\(domain)") else {
            return nil
        }
        
        return TokenExchangeFlow(issuer: issuerUrl,
                                 clientId: clientId,
                                 scopes: "openid profile offline_access",
                                 audience: .default)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // To sign in on launch
        signIn(silent: true)
        
        signInButton.isEnabled = flow != nil
        clientIdLabel.text = flow?.client.configuration.clientId
    }
    
    @IBAction private func signIn() {
        signIn(silent: false)
    }
    
    private func signIn(silent: Bool) {
        startAnimating()
        guard let deviceToken = deviceToken,
              let idToken = idToken
        else {
            stopAnimating()
            
            guard !silent else { return }
            
            let alert = UIAlertController(title: "No tokens found", message: "Device or/and ID tokens are not found.", preferredStyle: .alert)
            alert.addAction(.init(title: "Cancel", style: .cancel))
            
            if let webSignInScheme = URL(string: "websignin://"),
                UIApplication.shared.canOpenURL(webSignInScheme)
            {
                alert.addAction(.init(title: "Sign-in with WebSignIn", style: .default) { _ in
                    UIApplication.shared.open(webSignInScheme, options: [:])
                })
            }
            
            present(alert, animated: true)
            
            return
        }
        
        let tokens: [TokenExchangeFlow.TokenType] = [
            .actor(type: .deviceSecret, value: deviceToken),
            .subject(type: .idToken, value: idToken)
        ]
        
        flow?.start(with: tokens) { result in
            DispatchQueue.main.async {
                self.stopAnimating()
                
                switch result {
                case .failure(let error):
                    let alert = UIAlertController(title: "Cannot sign in", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.init(title: "OK", style: .default))
                    
                    self.present(alert, animated: true)
                    
                case .success(let token):
                    Credential.default = try? Credential.store(token)
                }
            }
        }
    }
    
    func startAnimating() {
        indicatorView.isHidden = false
    }
    
    func stopAnimating() {
        indicatorView.isHidden = true
    }
}
