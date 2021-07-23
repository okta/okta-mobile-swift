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
import OktaIdx
import AuthenticationServices

/// This class demonstrates how implementing signin with social auth providers can be implemented.
///
/// The completion handler supplied to the `login` function will be invoked once, either with a fatal error, or with a token.
///
/// Example:
///
/// ```swift
/// self.authHandler = SocialLogin(configuration: configuration)
/// self.authHandler?.login(service: .facebook)
/// { result in
///     switch result {
///     case .success(let token):
///         print(token)
///     case .failure(let error):
///         print(error)
///     }
/// }
/// ```
///
/// If you want to use a custom presentation context, you can optionally supply it to the login method.
public class SocialLogin {
    private let configuration: IDXClient.Configuration
    private weak var presentationContext: ASWebAuthenticationPresentationContextProviding?
    private var webAuthSession: ASWebAuthenticationSession?

    private var client: IDXClient?
    private var completion: ((Result<IDXClient.Token, LoginError>) -> Void)?
    
    public init(configuration: IDXClient.Configuration) {
        self.configuration = configuration
    }
    
    /// Public function used to initiate login using a given Social Authentication service.
    ///
    /// Optionally, a presentation context can be supplied when presenting the ASWebAuthenticationSession instance.
    /// - Parameters:
    ///   - service: Social service to authenticate against.
    ///   - presentationContext: Optional presentation context to present login from.
    ///   - completion: Completion handler called when authentication completes.
    public func login(service: IDXClient.Remediation.SocialAuth.Service, from presentationContext: ASWebAuthenticationPresentationContextProviding? = nil, completion: @escaping (Result<IDXClient.Token, LoginError>) -> Void) {
        self.presentationContext = presentationContext
        self.completion = completion
        
        // Initializes a new IDXClient with the supplied configuration.
        IDXClient.start(with: configuration) { (client, error) in
            guard let client = client else {
                self.finish(with: error)
                return
            }
            
            self.client = client

            // Performs the first request to IDX to retrieve the first response.
            client.resume { (response, error) in
                guard let response = response else {
                    self.finish(with: error)
                    return
                }
                
                // Find the Social IDP remediation that matches the requested social auth service.
                guard let remediation = response.remediations.first(where: { remediation in
                    let socialRemediation = remediation as? IDXClient.Remediation.SocialAuth
                    return socialRemediation?.service == service
                }) as? IDXClient.Remediation.SocialAuth
                else {
                    self.finish(with: .cannotProceed)
                    return
                }
                
                // Switch to the main queue to initiate the AuthenticationServices workflow.
                DispatchQueue.main.async {
                    self.login(with: remediation)
                }
            }
        }
    }
    
    func login(with remediation: IDXClient.Remediation.SocialAuth) {
        // Retrieve the Redirect URL scheme from our configuration, to
         // supply it to the ASWebAuthenticationSession instance.
        guard let client = client,
              let scheme = URL(string: client.context.configuration.redirectUri)?.scheme
        else {
            finish(with: .cannotProceed)
            return
        }

        // Create an ASWebAuthenticationSession to trigger the IDP OAuth2 flow.
        let session = ASWebAuthenticationSession(url: remediation.redirectUrl,
                                                 callbackURLScheme: scheme)
        { [weak self] (callbackURL, error) in
            // Ensure no error occurred, and that the callback URL is valid.
            guard error == nil,
                  let callbackURL = callbackURL,
                  let client = self?.client
            else {
                self?.finish(with: error)
                return
            }
            
            // Ask the IDXClient for what the result of the social login was.
            let result = client.redirectResult(for: callbackURL)
            
            switch result {
            case .authenticated:
                // When the social login result is `authenticated`, use the
                // IDXClient to exchange the callback URL returned from
                // ASWebAuthenticationSession with an Okta token.
                client.exchangeCode(redirect: callbackURL) { (token, error) in
                    guard let token = token else {
                        self?.finish(with: error)
                        return
                    }
                    self?.finish(with: token)
                }

            default:
                self?.finish(with: .cannotProceed)
            }
        }
        
        // Start and present the web authentication session.
        session.presentationContextProvider = presentationContext
        session.prefersEphemeralWebBrowserSession = true
        session.start()
        
        self.webAuthSession = session
    }
    
    public enum LoginError: Error {
        case error(_ error: Error)
        case message(_ string: String)
        case cannotProceed
        case unknown
    }
}

// Utility functions to help return responses to the caller.
extension SocialLogin {
    func finish(with error: Error?) {
        if let error = error {
            finish(with: .error(error))
        } else {
            finish(with: .unknown)
        }
    }
    
    func finish(with error: LoginError) {
        completion?(.failure(error))
        completion = nil
    }
    
    func finish(with token: IDXClient.Token) {
        completion?(.success(token))
        completion = nil
    }
}
