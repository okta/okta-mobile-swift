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

protocol IDXSigninController: AnyObject {
    var signin: Signin? { get set }
    func showError(_ error: Error, recoverable: Bool)
}
extension IDXSigninController where Self: UIViewController {
    func showError(_ error: Error, recoverable: Bool = false) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.showError(error, recoverable: recoverable)
            }
            return
        }
        
        let alert = UIAlertController(title: "Login error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        let parentController = navigationController?.presentingViewController
        if recoverable {
            present(alert, animated: true)
        } else {
            dismiss(animated: true) {
                parentController?.present(alert, animated: true) {
                    self.signin?.failure(with: error)
                }
            }
        }
    }
}

protocol IDXResponseController: IDXSigninController {
    var response: IDXClient.Response? { get set }
}
