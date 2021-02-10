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

/// Sign in controller used when initializing the signin process. This encapsulates the `IDXClient.start()` API call.
class IDXStartViewController: UIViewController, IDXSigninController {
    var signin: Signin?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }
        
        signin.idx.start { [weak self] (_, response, error) in
            guard let response = response else {
                if let error = error {
                    self?.showError(error)
                    
                    signin.failure(with: error)
                }
                return
            }
            
            signin.proceed(to: response)
        }
    }
}
