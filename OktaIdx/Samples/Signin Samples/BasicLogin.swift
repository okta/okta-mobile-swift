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
/// Example:
///
/// ```swift
/// let auth = BasicLogin(issuer: URL(string: "https://example.okta.com/oauth2/default")!,
///                       clientId: "0oabcde12345",
///                       scopes: "openid profile offline_access",
///                       redirectUri: URL(string: "com.example.myapp:/callback")!)
/// let token = try await auth.login(username: "user@example.com",
///                                  password: "secretPassword")
/// ```
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
public class BasicLogin {
    let flow: InteractionCodeFlow
    
    public init(issuer: URL,
                clientId: String,
                scopes: String,
                redirectUri: URL)
    {
        // Initializes the flow which can be used later in the process.
        flow = InteractionCodeFlow(issuer: issuer,
                                   clientId: clientId,
                                   scopes: scopes,
                                   redirectUri: redirectUri)
    }
    
    /// Public method that initiates the login flow.
    /// - Parameters:
    ///   - username: Username to log in with.
    ///   - password: Password for the given username.
    public func login(username: String, password: String) async throws -> Token {
        // Starts authentication, getting the first initial response. This
        // usually is a prompt to input the user's identifier (username), and
        // depending on policy settings, may also include a field for the user's
        // password.
        var response = try await flow.start()

        // Proceed through each form response, until we successfully sign in.
        while !response.isLoginSuccessful {
            // If any error messages are returned, report them and abort the process.
            if let message = response.messages.allMessages.first {
                throw LoginError.message(message.message)
            }
            
            // Find the remediation asking for the user's identifier, and supply
            // the user's username.
            if let remediation = response.remediations[.identify],
               let usernameField = remediation["identifier"]
            {
                usernameField.value = username
                
                // Sometimes the form allows the password to be supplied in the same
                // remediation, so we should try to pass that along now.
                remediation["credentials.passcode"]?.value = password
                
                // Proceed through the remediation to receive the next form.
                response = try await remediation.proceed()
            }
            
            // Find the password authenticator challenge remediation, to supply
            // the user's password.
            else if let remediation = response.remediations[.challengeAuthenticator],
                    let passwordField = remediation["credentials.passcode"]
            {
                guard remediation.authenticators.contains(where: { $0.type == .password })
                else {
                    throw LoginError.unexpectedAuthenticator
                }
                
                passwordField.value = password
                
                // Proceed through the remediation to receive the next form.
                response = try await remediation.proceed()
            }
            
            // We've received a remediation we don't expect.
            else {
                throw LoginError.cannotProceed
            }
        }
        
        // Exchange the successful response with a token.
        return try await response.exchangeCode()
    }
    
    public enum LoginError: Error {
        case error(_ error: Error)
        case message(_ string: String)
        case cannotProceed
        case unexpectedAuthenticator
        case unknown
    }
}
