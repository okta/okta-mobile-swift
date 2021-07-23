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

import Foundation
import OktaIdx

/// This class demonstrates how implementing signin with basic username / password can be implemented.
///
/// The completion handler supplied to the `login` function will be invoked once, either with a fatal error, or with a token.
///
/// Example:
///
/// ```swift
/// self.authHandler = BasicLogin(configuration: configuration)
/// self.authHandler?.login(username: "user@example.com",
///                         password: "secretPassword")
/// { result in
///     switch result {
///     case .success(let token):
///         print(token)
///     case .failure(let error):
///         print(error)
///     }
/// }
/// ```
public class BasicLogin {
    let configuration: IDXClient.Configuration
    var username: String?
    var password: String?
    
    var client: IDXClient?
    var completion: ((Result<IDXClient.Token, LoginError>) -> Void)?
    
    public init(configuration: IDXClient.Configuration) {
        self.configuration = configuration
    }
    
    /// Public method that initiates the login flow.
    /// - Parameters:
    ///   - username: Username to log in with.
    ///   - password: Password for the given username.
    ///   - completion: Comletion block invoked when login completes.
    public func login(username: String, password: String, completion: @escaping (Result<IDXClient.Token, LoginError>) -> Void) {
        self.username = username
        self.password = password
        self.completion = completion
        
        IDXClient.start(with: configuration) { (client, error) in
            guard let client = client else {
                self.finish(with: error)
                return
            }
            
            self.client = client

            // Assign ourselves as the delegate receiver, to be notified
            // when responses or errors are returned.
            client.delegate = self
            
            // Calls the IDX API to receive the first IDX response.
            client.resume(completion: nil)
        }
    }
    
    public enum LoginError: Error {
        case error(_ error: Error)
        case message(_ string: String)
        case cannotProceed
        case unexpectedAuthenticator
        case unknown
    }
}

/// Implementation details of performing basic username/password authentication.
extension BasicLogin: IDXClientDelegate {
    // Delegate method sent when an error occurs.
    public func idx(client: IDXClient, didReceive error: Error) {
        finish(with: error)
    }
    
    // Delegate method sent when a token is successfully exchanged.
    public func idx(client: IDXClient, didReceive token: IDXClient.Token) {
        finish(with: token)
    }
    
    // Delegate method invoked whenever an IDX response is received, regardless
    // of what action or remediation is called.
    public func idx(client: IDXClient, didReceive response: IDXClient.Response) {
        // If a response is successful, immediately exchange it for a token.
        guard !response.isLoginSuccessful else {
            response.exchangeCode(completion: nil)
            return
        }
        
        // If no remediations are present, abort the login process.
        guard let remediation = response.remediations.first else {
            finish(with: .cannotProceed)
            return
        }
        
        // If any error messages are returned, report them and abort the process.
        if let message = response.messages.allMessages.first {
            finish(with: .message(message.message))
            return
        }
        
        // Handle the various remediation choices the client may be presented with within this policy.
        switch remediation.type {
        case .identify:
            remediation.identifier?.value = username
            remediation.credentials?.passcode?.value = password
            remediation.proceed(completion: nil)
                        
        // In identify-first policies, the password is supplied on a separate response.
        case .challengeAuthenticator:
            guard remediation.authenticators.first?.type == .password else {
                finish(with: .unexpectedAuthenticator)
                return
            }
            
            remediation.credentials?.passcode?.value = password
            remediation.proceed(completion: nil)
            
        default:
            finish(with: .cannotProceed)
        }
    }
}

// Utility functions to help return responses to the caller.
extension BasicLogin {
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
