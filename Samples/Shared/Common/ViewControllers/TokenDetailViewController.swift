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
import AuthFoundation

class TokenDetailViewController: UIViewController {
    var credential: Credential? {
        didSet {
            DispatchQueue.main.async {
                self.drawToken()
            }
        }
    }

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged,
                                               object: nil,
                                               queue: .main) { (notification) in
            guard let credential = notification.object as? Credential else { return }
            self.credential = credential
        }
        credential = Credential.default
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Revoke", style: .plain, target: self, action: #selector(revokeAction(_:)))
    }
    
    @objc
    func revokeAction(_ sender: Any) {
        let alert = UIAlertController(title: "Revoke Tokens", message: nil, preferredStyle: .actionSheet)
    
        let names: [(String, Token.RevokeType)] = [
            ("Access Token", .accessToken),
            ("Refresh Token", .refreshToken),
            ("Device Secret", .deviceSecret),
            ("All Tokens", .all)
        ]
    
        for (name, type) in names {
            alert.addAction(.init(title: name, style: .destructive) { _ in
                self.revoke(type)
            })
        }
    
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func revoke(_ kind: Token.RevokeType) {
        guard let credential = credential else { return }
        let busyAlert = UIAlertController(title: "Revoking", message: nil, preferredStyle: .alert)
        present(busyAlert, animated: true)
    
        credential.revoke(type: kind) { result in
            DispatchQueue.main.async {
                busyAlert.dismiss(animated: true) {
                    guard case let .failure(error) = result else { return }
    
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(.init(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    func drawToken() {
        guard let token = credential?.token else {
            textView.text = "No token was found"
            return
        }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byCharWrapping
        paragraph.paragraphSpacing = 15
        
        let bold = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)]
        let normal = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
                      NSAttributedString.Key.paragraphStyle: paragraph]
        
        func addString(to string: NSMutableAttributedString, title: String, value: String) {
            string.append(NSAttributedString(string: "\(title):\n", attributes: bold))
            string.append(NSAttributedString(string: "\(value)\n", attributes: normal))
        }
        
        let string = NSMutableAttributedString()
        addString(to: string, title: "Expires in", value: "\(token.expiresIn) seconds")
        addString(to: string, title: "Scope", value: token.scope ?? "N/A")
        addString(to: string, title: "Token type", value: token.tokenType)
        
        addString(to: string, title: "Access token", value: token.accessToken)
        
        if let refreshToken = token.refreshToken {
            addString(to: string, title: "Refresh token", value: refreshToken)
        }
        
        if let idToken = token.idToken {
            addString(to: string, title: "ID token", value: idToken.rawValue)
        }
        
        textView.attributedText = string
    }
}
