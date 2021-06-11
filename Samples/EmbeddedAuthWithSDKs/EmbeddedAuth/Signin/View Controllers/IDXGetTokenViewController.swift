/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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

/// Sign in view controller used when login is successful, and encapsulates the `IDXClient.Response.getToken()` method.
class IDXGetTokenViewController: UIViewController, IDXResponseController {
    var signin: Signin?
    var response: IDXClient.Response?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)

        guard let signin = signin,
              let response = response else
        {
            showError(SigninError.genericError(message: "Signin session or response is missing"))
            return
        }
        
        response.exchangeCode { [weak self] (token, error) in
            guard let token = token else {
                if let error = error {
                    self?.showError(error)
                    
                    signin.failure(with: error)
                }
                return
            }
            
            signin.success(with: token)
        }
    }
}
