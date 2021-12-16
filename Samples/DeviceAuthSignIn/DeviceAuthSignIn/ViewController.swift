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
import OktaOAuth2

class ViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var codeStackView: UIStackView!
    @IBOutlet weak var urlPromptLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    
    var flow: DeviceAuthorizationFlow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        flow = DeviceAuthorizationFlow(issuer: URL(string: "https://{domain}")!,
//                                       clientId: "{client_id}",
//                                       scopes: "openid profile email offline_access")
        flow = DeviceAuthorizationFlow(issuer: URL(string: "https://idx-devex.trexcloud.com")!,
                                       clientId: "0oa3kwpkybLg4AQHH0g7",
                                       scopes: "openid profile email offline_access")

        codeStackView.isHidden = true
        activityIndicator.startAnimating()
        
        flow?.resume() { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.show(error)
                case .success(let context):
                    self.show(context)
                }
            }
        }
    }

    func show(_ error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func show(_ context: DeviceAuthorizationFlow.Context) {
        update(prompt: context.verificationUri)
        update(code: context.userCode)
        codeStackView.isHidden = false
        activityIndicator.stopAnimating()
        
        flow?.resume(with: context) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.show(error)
                case .success(let token):
                    UserManager.shared.current = User(token: token,
                                                      info: User.Info(familyName: "Nachbaur",
                                                                      givenName: "Mike",
                                                                      name: "Mike Nachbaur",
                                                                      preferredUsername: "Mike",
                                                                      sub: "foo",
                                                                      updatedAt: Date(),
                                                                      locale: "en-US",
                                                                      zoneinfo: "foo"))
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    func update(prompt url: URL) {
        let textColor = (traitCollection.userInterfaceStyle == .light) ? UIColor.black : UIColor.white
        let urlString = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let mutableString = NSMutableAttributedString(string: "To sign in, visit \(urlString) and enter the following code:",
                                                      attributes: [
                                                        .foregroundColor: textColor
                                                      ])

        guard let range = mutableString.string.range(of: urlString),
              let linkColor = urlPromptLabel.tintColor
        else {
            urlPromptLabel.attributedText = mutableString
            return
        }
        
        mutableString.setAttributes([ .foregroundColor: linkColor ],
                                    range: NSRange(range, in: mutableString.string))
        urlPromptLabel.attributedText = mutableString
    }
    
    func update(code: String) {
        var code = code
        code.insert(" ", at: code.index(code.startIndex, offsetBy: code.count / 2))
        
        codeLabel.attributedText = NSAttributedString(string: code, attributes: [
            .kern: 30
        ])
    }
}

