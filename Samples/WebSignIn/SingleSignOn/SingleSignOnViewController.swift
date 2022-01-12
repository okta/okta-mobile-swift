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
    
    private lazy var oktaConfiguration: [String: String] = {
        guard let oktaPlistUrl = Bundle.main.url(forResource: "Okta", withExtension: "plist"),
              oktaPlistUrl.isFileURL
        else
        {
            assertionFailure("Cannot load Okta.plist. Make sure it's included into app target.")
            return [:]
        }
        
        let plistContent: Any
        
        do {
            let data = try Data(contentsOf: oktaPlistUrl)
            plistContent = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            assertionFailure("Cannot load data from Okta.plist.")
            return [:]
        }
        
        guard let plistDictionary = plistContent as? [String: String] else {
            assertionFailure("Cannot parse data from Okta.plist.")
            return [:]
        }
        
        return plistDictionary
    }()
    
    private lazy var issuer: String = {
        guard let issuer = oktaConfiguration["issuer"] else {
            assertionFailure("Cannot get `issuer`.")
            return ""
        }
        
        return issuer
    }()
    
    private var deviceToken: String? {
        try? Keychain.get(key: "Okta-Device-Token", accessGroup: "com.okta.mobile-sdk.shared") as String
    }
    
    private var idToken: String? {
        try? Keychain.get(key: "Okta-Id-Token", accessGroup: "com.okta.mobile-sdk.shared") as String
    }
    
    private var flow: TokenExchangeFlow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signIn(silent: true)
        
        clientIdLabel.text = issuer
    }
    
    @IBAction private func signIn() {
        signIn(silent: false)
    }
    
    private func signIn(silent: Bool) {
        guard
            let deviceSecret = deviceToken,
            let idToken = idToken
        else
        {
            if silent {
                return
            }
            
            let alert = UIAlertController(title: "No tokens found", message: "Device or/and ID tokens are not found.", preferredStyle: .alert)
            alert.addAction(.init(title: "Cancel", style: .cancel))
            
            if
                let webSignInScheme = URL(string: "websignin://"),
                UIApplication.shared.canOpenURL(webSignInScheme)
            {
                alert.addAction(.init(title: "Sign-in with WebSignIn", style: .default) { _ in
                    UIApplication.shared.open(webSignInScheme, options: [:])
                })
            }
            
            present(alert, animated: true)
            
            return
        }
        
        flow = initializeFlow()
        
        let tokens: [TokenExchangeFlow.TokenType] = [
            .actor(type: .deviceSecret, value: deviceSecret),
            .subject(type: .idToken, value: idToken)
        ]
        
        flow?.resume(with: tokens) { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Cannot sign in", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.init(title: "OK", style: .default))
                    
                    self.present(alert, animated: true)
                }
                
            case .success(let token):
                UserManager.shared.current = User(
                    token: token,
                    info: .init(familyName: "",
                                givenName: "",
                                name: "",
                                preferredUsername: "",
                                sub: "",
                                updatedAt: Date(),
                                locale: "",
                                zoneinfo: ""))
            }
        }
    }
    
    private func initializeFlow() -> TokenExchangeFlow? {
        guard
            let issuer = URL(string: issuer),
            let clientId = oktaConfiguration["clientId"],
            let scope = oktaConfiguration["scopes"]?.replacingOccurrences(of: "device_sso", with: "")
        else
        {
            return nil
        }
        
        return TokenExchangeFlow(issuer: issuer,
                                 clientId: clientId,
                                 scopes: scope,
                                 audience: .default)
    }
}

