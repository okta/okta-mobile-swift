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
import AuthenticationServices

enum SigninError: Error {
    case genericError(message: String)
    case stepUnsupported
    case invalidUrl
}

/// Signin wrapper that uses the Okta IDX client to step through the series
/// of remediation steps necessary to sign a user in.
public class Signin {
    private let storyboard: UIStoryboard
    private var completion: ((User?, Error?) -> Void)?
    private var navigationController: UINavigationController?
    
    internal let configuration: IDXClient.Configuration
    internal var idx: IDXClient?
    
    /// Initializes a signin instance with the given client configuration.
    /// - Parameter configuration: Client app configuration.
    init(using configuration: IDXClient.Configuration) {
        self.configuration = configuration
        self.storyboard = UIStoryboard(name: "IDXSignin", bundle: Bundle(for: type(of: self)))
    }
    
    convenience init?() {
        guard let configuration = UserManager.shared.configuration else {
            return nil
        }
        self.init(using: configuration)
    }
    
    /// Begins the signin UI, presented from the given presenting view controller.
    /// - Parameter viewController: View controller to modally present the sign in navigation controller from.
    /// - Returns: Future to represent the completion of the signin process.
    public func signin(from viewController: UIViewController, completion: @escaping (User?, Error?) -> Void) {
        guard let controller = self.storyboard.instantiateViewController(identifier: "start") as? IDXStartViewController else {
            completion(nil, SigninError.genericError(message: "Cannot find story board controller \"start\""))
            return
        }
        
        controller.signin = self
        self.completion = completion
        
        let navigationController = UINavigationController(rootViewController: controller)
        self.navigationController = navigationController
        
        viewController.present(navigationController, animated: true, completion: nil)
    }
    
    internal func buttonTitle(for option: Remediation?) -> String? {
        guard let option = option else {
            return "Restart"
        }
        
        switch option.type {
        case .skip:
            return "Skip"
            
        case .selectEnrollProfile, .enrollProfile:
            return "Sign Up"
            
        case .selectIdentify, .identify:
            return "Sign In"
            
        case .redirectIdp:
            guard let socialOption = option.socialIdp else {
                return "Social Login"
            }

            switch socialOption.service {
            case .facebook:
                return "Login with Facebook"
            case .google:
                return "Login with Google"
            default:
                return "Social Login"
            }
            
        case .selectAuthenticatorAuthenticate:
            return "Choose"
            
        case .launchAuthenticator:
            return "Launch Authenticator"
            
        case .cancel:
            return "Restart"
            
        case .unlockAccount:
            return "Unlock Account"
            
        default:
            return "Continue"
        }
    }
    
    /// Called by each view controller once their remediation step has been completed, allowing it to proceed to the next step of the workflow.
    /// - Parameter response: IDX response object received from the API.
    func proceed(to response: Response) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.proceed(to: response)
            }
            return
        }
        
        guard let navigationController = navigationController else {
            failure(with: SigninError.genericError(message: "Navigation controller undefined"))
            return
        }
        
        guard let controller = controller(for: response) else {
            if let message = response.messages.first {
                let alert = UIAlertController(title: "Error",
                                              message: message.message,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    self.failure(with: SigninError.genericError(message: "Cancelled login"))
                }))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    if response.canCancel {
                        response.cancel { (response, error) in
                            guard let response = response else {
                                self.failure(with: SigninError.genericError(message: "Something went horribly wrong"))
                                return
                            }
                            DispatchQueue.main.async {
                                self.proceed(to: response)
                            }
                        }
                    }
                }))
                navigationController.present(alert, animated: true, completion: nil)
            } else {
                failure(with: SigninError.genericError(message: "Could not find a controller for this response"))
            }
            return
        }
        
        // Don't animate between controllers of the same type, to avoid
        // annoying animations
        var animated = true
        if let previousController = navigationController.topViewController {
            if type(of: previousController) === type(of: controller) {
                animated = false
            }
        }
        
        navigationController.setViewControllers([controller], animated: animated)
    }
    
    /// Initializes the appropriate view controller for this response.
    /// - Parameter response: IDX client response that needs a view controller.
    /// - Returns: View controller to display, or `nil` if no controller was available
    private func controller(for response: Response) -> UIViewController? {
        // If the login is successful, there are no remediation options left. In this case,
        // we create a view controller to show the progress as a token is exchanged.
        if response.isLoginSuccessful {
            guard let controller = storyboard.instantiateViewController(identifier: "get-token") as? UIViewController & IDXResponseController else { return nil }
            controller.signin = self
            controller.response = response
            
            return controller
        }
        
        // If no remediation options are available, this response probably just contains
        // error messages, so we should remain on our current form.
        guard !response.remediations.isEmpty else { return nil }

        // Attempt to instantiate a view controller to represent the remediation options in this response.
        if let controller = storyboard.instantiateViewController(identifier: "remediation") as? UIViewController & IDXResponseController {
            controller.signin = self
            controller.response = response
            return controller
        }

        return nil
    }
    
    /// Called by the signin view controllers when the Future should fail.
    /// - Parameter error: The error to pass to the future.
    internal func failure(with error: Error) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.failure(with: error)
            }
            return
        }
        
        self.navigationController?.dismiss(animated: true) {
            guard let completion = self.completion else { return }
            defer { self.completion = nil }
            completion(nil, error)
        }
    }
    
    /// Called by the signin view controllers when the Future should succeed.
    /// - Parameter token: The token produced at the end of the signin process.
    internal func success(with token: Token) {
        let userinfoUrl: URL
        do {
            userinfoUrl = try configuration.url(for: "/v1/userinfo")
        } catch {
            failure(with: error)
            return
        }
        
        guard let completion = self.completion else { return }
        defer { self.completion = nil }

        var request = URLRequest(url: userinfoUrl)
        token.authorize(request: &request)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                self.failure(with: error ?? SigninError.genericError(message: "Invalid user profile response"))
                return
            }
            
            do {
                let userinfo = try User.Info.jsonDecoder.decode(User.Info.self, from: data)
                let user = User(token: token, info: userinfo)
                
                DispatchQueue.main.async {
                    self.navigationController?.dismiss(animated: true) {
                        completion(user, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.failure(with: error)
                }
            }
        }.resume()
    }
}
