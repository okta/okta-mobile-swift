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
import CoreImage.CIFilterBuiltins

class ViewController: UIViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var codeStackView: UIStackView!
    @IBOutlet weak var urlPromptLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var codeImageView: UIImageView!
    @IBOutlet weak var openAuthenticationButton: UIButton?
    
    var flow: DeviceAuthorizationFlow?
    
    lazy var domain: String = {
        ProcessInfo.processInfo.environment["E2E_DOMAIN"] ?? "<#domain#>"
    }()
    
    lazy var clientId: String = {
        ProcessInfo.processInfo.environment["E2E_CLIENT_ID"] ?? "<#client_id#>"
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !domain.isEmpty,
           let issuerUrl = URL(string: "https://\(domain)")
        {
            flow = DeviceAuthorizationFlow(issuer: issuerUrl,
                                           clientId: clientId,
                                           scopes: "openid profile email offline_access")
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Client not configured", message: "Please update ViewController.swift", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }

        codeStackView.isHidden = true
        openAuthenticationButton?.isHidden = true
        activityIndicator.startAnimating()
        codeImageView.layer.magnificationFilter = .nearest
        
        signIn()
    }

    func signIn() {
        guard let flow = flow else {
            return
        }

        flow.start { result in
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
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
            self.signIn()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func show(_ context: DeviceAuthorizationFlow.Context) {
        update(prompt: context.verificationUri)
        update(qrCode: context.verificationUriComplete)
        update(code: context.userCode)
        codeStackView.isHidden = false
        activityIndicator.stopAnimating()

        if ProcessInfo.processInfo.arguments.contains("--enable-browser") {
            openAuthenticationButton?.isHidden = false
        }

        flow?.resume(with: context) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.show(error)
                case .success(let token):
                    Credential.default = try? Credential.store(token)
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    func update(prompt url: URL) {
        let textColor = (traitCollection.userInterfaceStyle == .light) ? UIColor.black : UIColor.white
        let urlString = url.absoluteString.replacingOccurrences(of: "https://", with: "")
        let mutableString = NSMutableAttributedString(string: "Visit \(urlString) and enter the following code:",
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
    
    func update(qrCode url: URL?) {
        guard let url = url else {
            codeImageView.isHidden = true
            return
        }
        
        var image: UIImage?
        defer {
            codeImageView.image = image
        }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = url.absoluteString.data(using: .utf8) else {
            return
        }
        
        filter.message = data
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return
        }
        
        image = UIImage(cgImage: cgImage)
        codeImageView.isHidden = false
    }
    
    func update(code: String) {
        var code = code
        code.insert(" ", at: code.index(code.startIndex, offsetBy: code.count / 2))
        
        codeLabel.attributedText = NSAttributedString(string: code, attributes: [
            .kern: 30
        ])
    }
}
