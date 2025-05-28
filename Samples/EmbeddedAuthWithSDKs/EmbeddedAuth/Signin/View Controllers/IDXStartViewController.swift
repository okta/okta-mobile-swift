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

/// Sign in controller used when initializing the signin process. This encapsulates the `InteractionCodeFlow.start()` API call.
class IDXStartViewController: UIViewController, IDXSigninController {
    var signin: Signin?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        guard let signin = signin else {
            showError(SigninError.genericError(message: "Signin session deallocated"))
            return
        }

        var context = InteractionCodeFlow.Context()
        if let recoveryToken = ClientConfiguration.active?.recoveryToken {
            context.recoveryToken = recoveryToken
        }

        Task { @MainActor in
            do {
                signin.proceed(to: try await signin.flow.start(with: context))
            } catch {
                showError(error)
                signin.failure(with: error)
            }
        }
    }
}
