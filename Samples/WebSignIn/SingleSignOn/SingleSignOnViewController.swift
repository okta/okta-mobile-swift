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

    private var flow: AuthorizationSSOFlow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signIn()
        
        clientIdLabel.text = issuer
    }
    
    @IBAction private func signIn() {
        flow = initializeFlow()
        
        try? flow?.start { result in
            switch result {
            case .failure(let error):
                let alert = UIAlertController(title: "Cannot sign in", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .default))
                
                self.present(alert, animated: true)
            case .success:
                self.authorize()
            }
        }
    }
    
    private func authorize() {
        flow?.authorize { result in
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
    
    private func initializeFlow() -> AuthorizationSSOFlow? {
        guard
            let issuer = URL(string: issuer),
            let clientId = oktaConfiguration["clientId"],
            let scope = oktaConfiguration["scopes"]?.replacingOccurrences(of: "device_sso", with: "")
        else
        {
            return nil
        }
        
        guard
            let deviceSecret = deviceToken,
            let idToken = idToken
        else
        {
            print("[ERROR]: Cannot find `deviceSecret` and/or `idToken` in Keychain.")
            return nil
        }

        return AuthorizationSSOFlow(issuer: issuer,
                                    clientId: clientId,
                                    scopes: scope,
                                    deviceSecret: deviceSecret,
                                    idToken: idToken,
                                    audience: .default)
    }
}

