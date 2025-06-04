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

/// This class demonstrates how implementing signin with username, an optional password, and multiple factors.
///
/// The completion handler supplied to the `login` function will be invoked once, either with a fatal error, or with a token. When decisions need to be made during authentication (e.g. selecting an authenticator, or prompting the user for an MFA verification code), the `stepHandler` block supplied in the initializer will be called, giving you the option to interact with the authentication flow.
///
/// Example:
///
/// ```swift
/// self.authHandler = MultifactorLogin(
///     issuer: URL(string: "https://example.okta.com/oauth2/default")!,
///     clientId: "0oabcde12345",
///     scopes: "openid profile offline_access",
///     redirectUri: URL(string: "com.example.myapp:/callback")!))
/// { step in
///     switch step {
///     case .chooseFactor(let factors):
///         // Use this to prompt the user for the factor you'd like to authenticate with.
///         if factors.contains(.email) {
///             self.authHandler?.select(factor: .email)
///         }
///
///     case .verifyCode(factor: let factor):
///         // Prompt the user for the verification code; when they supply it, call the `verify` function.
///         if factor == .email {
///             self.authHandler?.verify(code: "123456")
///         }
///     }
///
///     case .chooseMethod(let methods):
///         // Use this to prompt the user for the method you'd like to authenticate with.
///         if methods.contains(.sms) {
///             self.authHandler?.select(factor: .phone,
///                                      method: .sms,
///                                      phoneNumber: "+15551234567")
///         }
///     }
/// }
///
/// self.authHandler.login(username: "user@example.com",
///                        password: "secretPassword")
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
/// Or, for user registration:
/// ```Swift
/// self.authHandler.register(username: "user@example.com",
///                           password: "secretPassword",
///                           profile: [
///                               .firstName: "Jane",
///                               .lastName: "Doe"
///                           ])
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
/// Or to reset a user's password:
/// ```Swift
/// self.authHandler.resetPassword(username: "user@example.com")
/// { result in
///     switch result {
///     case .success(let token):
///         print(token)
///     case .failure(let error):
///         print(error)
///     }
/// }
///```
public class MultifactorLogin {
    var username: String?
    var password: String?
    let stepHandler: ((Step) -> Void)?
    var profile: [ProfileField: String]?

    let flow: InteractionCodeFlow
    var response: Response?
    var completion: ((Result<Token, LoginError>) -> Void)?
    
    /// Initializer used to create a multifactor login session.
    /// - Parameters:
    ///   - issuer: The authorization server issuer URL.
    ///   - clientId: The application's client ID.
    ///   - scopes: The scopes to use for the resulting token.
    ///   - redirectUri: The application's redirect URI.
    ///   - stepHandler: Closure used when input from the user is needed.
    public init(issuer: URL,
                clientId: String,
                scopes: String,
                redirectUri: URL,
                stepHandler: @escaping (Step) -> Void)
    {
        // Initializes the flow which can be used later in the process.
        flow = InteractionCodeFlow(issuer: issuer,
                                   clientId: clientId,
                                   scopes: scopes,
                                   redirectUri: redirectUri)
        self.stepHandler = stepHandler
        
        flow.add(delegate: self)
    }
    
    /// Public method that initiates the login flow.
    /// - Parameters:
    ///   - username: Username to log in with.
    ///   - password: Password for the given username.
    ///   - completion: Comletion block invoked when login completes.
    public func login(username: String, password: String, completion: @escaping (Result<Token, LoginError>) -> Void) {
        self.username = username
        self.password = password
        self.completion = completion
        
        flow.start(completion: nil)
    }
    
    /// Public function used to initiate self-service user registration.
    /// - Parameters:
    ///   - username: Username to register with.
    ///   - password: Password to select.
    ///   - profile: Profile information (e.g. firstname / lastname) for the new user.
    ///   - completion: Completion block invoked when registration completes.
    public func register(username: String, password: String, profile: [ProfileField: String], completion: @escaping (Result<Token, LoginError>) -> Void) {
        self.username = username
        self.password = password
        self.profile = profile
        self.completion = completion
        
        flow.start(completion: nil)
    }
    
    /// Public function to initiate a password reset for an existing user.
    ///
    /// The `stepHandler` supplied to the initializer is used for factor verification and password selection.
    /// - Parameters:
    ///   - username: Username to reset.
    ///   - completion: Completion block invoked when registration completes.
    public func resetPassword(username: String, completion: @escaping (Result<Token, LoginError>) -> Void) {
        self.username = username
        self.completion = completion
       
        flow.start(completion: nil)
    }
    
    /// Method called by you to select an authenticator. This can be used in response to a `Step.chooseFactor` stepHandler call.
    /// - Parameter factor: Factor to select, or `nil` to skip.
    public func select(factor: Authenticator.Kind?) {
        guard let remediation = response?.remediations[.selectAuthenticatorAuthenticate] ?? response?.remediations[.selectAuthenticatorEnroll],
              let authenticatorsField = remediation["authenticator"]
        else {
            finish(with: .cannotProceed)
            return
        }
        
        if let factor = factor {
            let factorField = authenticatorsField.options?.first(where: { field in
                field.authenticator?.type == factor
            })
            authenticatorsField.selectedOption = factorField
            remediation.proceed(completion: nil)
        } else if let skipRemediation = response?.remediations[.skip] {
            skipRemediation.proceed(completion: nil)
        } else {
            finish(with: .cannotProceed)
            return
        }
    }

    /// Method called by you to select an authentication factor method.
    ///
    /// This can be used in response to a `Step.chooseMethod` stepHandler call.
    ///
    /// Typically this is used to select either SMS or Voice when using a Phone factor.
    /// When enrolling in a new factor, the phone number should be supplied with
    /// the format: `+15551234567`. (e.g. + followed by the country-code and phone number).
    /// - Parameters:
    ///   - factor: Factor being selected.
    ///   - method: Factor method (e.g. SMS or Voice) to select.
    ///   - phoneNumber: Optional phone number to supply, when enrolling in a new factor.
    public func select(factor: Authenticator.Kind,
                       method: Authenticator.Method,
                       phoneNumber: String? = nil)
    {
        // Retrieve the appropriate remedation, authentication factor field and method, to
         // select the appropriate method type.
        guard let remediation = response?.remediations[.selectAuthenticatorAuthenticate] ?? response?.remediations[.selectAuthenticatorEnroll],
              let authenticatorsField = remediation["authenticator"],
              let factorField = authenticatorsField.options?.first(where: { field in
                field.authenticator?.type == factor
              }),
              let methodOption = factorField["methodType"]?.options?.first(where: { field in
                field.value as? String == method.stringValue
              })
        else {
            finish(with: .cannotProceed)
            return
        }
        
        authenticatorsField.selectedOption = methodOption
        factorField["phoneNumber"]?.value = phoneNumber

        remediation.proceed(completion: nil)
    }
    
    /// Method used to verify a factor.
    ///
    /// When a factor is selected, the user will receive a verification code. Once they receive it, you will use this method to supply it back to Okta.
    /// - Parameter code: Verification code received and supplied by the user.
    public func verify(code: String) {
        guard let remediation = response?.remediations[.challengeAuthenticator] ?? response?.remediations[.enrollAuthenticator]
        else {
            finish(with: .cannotProceed)
            return
        }
        
        remediation.credentials?.passcode?.value = code
        remediation.proceed(completion: nil)
    }
    
    /// Enumeration representing the different actionable steps that the
    /// `stepHandler` can receive.
    ///
    /// You can use these values to determine what UI to present to the user to select factors, authenticator methods, and to verify authenticator verification codes.
    public enum Step {
        case chooseFactor(_ factors: [Authenticator.Kind])
        case chooseMethod(_ methods: [Authenticator.Method])
        case verifyCode(factor: Authenticator.Kind)
    }
    
    public enum ProfileField: String {
        case firstName, lastName
    }
    
    public enum LoginError: Error {
        case error(_ error: Error)
        case message(_ string: String)
        case cannotProceed
        case unexpectedAuthenticator
        case noStepHandler
        case unknown
    }
}

extension MultifactorLogin: InteractionCodeFlowDelegate {
    // Delegate method sent when an error occurs.
    public func authentication<Flow: InteractionCodeFlow>(flow: Flow, didReceive error: Error) {
        finish(with: error)
    }
    
    // Delegate method sent when a token is successfully exchanged.
    public func authentication<Flow: InteractionCodeFlow>(flow: Flow, didReceive token: Token) {
        finish(with: token)
    }
    
    // Delegate method invoked whenever an IDX response is received, regardless
    // of what action or remediation is called.
    public func authentication<Flow: InteractionCodeFlow>(flow: Flow, didReceive response: Response) {
        self.response = response
        
        // If a response is successful, immediately exchange it for a token.
        guard !response.isLoginSuccessful else {
            response.exchangeCode(completion: nil)
            return
        }
        
        // If we can select enroll profile, immediately proceed to that.
        if let remediation = response.remediations[.selectEnrollProfile],
           profile != nil
        {
            remediation.proceed(completion: nil)
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
        
        // If we have no password, we assume we're performing an account recovery.
        if password == nil,
           (remediation.type == .identify || remediation.type == .challengeAuthenticator),
           let passwordAuthenticator = response.authenticators.current as? Authenticator.Password
        {
            passwordAuthenticator.recover(completion: nil)
            return
        }

        // Handle the various remediation choices the client may be presented with within this policy.
        switch remediation.type {
        case .identify: fallthrough
        case .identifyRecovery:
            remediation.identifier?.value = username
            remediation.credentials?.passcode?.value = password
            remediation.proceed(completion: nil)
            
        // The challenge authenticator remediation is used to request a passcode
         // of some sort from the user, either the user's password, or an
         // authenticator verification code.
        case .enrollAuthenticator: fallthrough
        case .challengeAuthenticator:
            guard let authenticator = remediation.authenticators.first else {
                finish(with: .unexpectedAuthenticator)
                return
            }
            
            switch authenticator.type {
            // The challenge authenticator remediation is used to request a passcode
             // of some sort from the user, either the user's password, or an
             // authenticator verification code.
            case .password:
                if let password = password {
                    remediation.credentials?.passcode?.value = password
                    remediation.proceed(completion: nil)
                } else {
                    fallthrough
                }

            default:
                guard let stepHandler = stepHandler else {
                    finish(with: .noStepHandler)
                    return
                }
                
                stepHandler(.verifyCode(factor: authenticator.type))
            }
                        
        case .selectAuthenticatorEnroll: fallthrough
        case .selectAuthenticatorAuthenticate:
            // Find the factor types available to the user at this time.
            let factors: [Authenticator.Kind]
            factors = remediation["authenticator"]?
                .options?.compactMap({ field in
                    field.authenticator?.type
                }) ?? []
            
            // If a password is supplied, immediately select the password factor if it's given as a choice.
            if factors.contains(.password) && password != nil {
                select(factor: .password)
            } else {
                guard let stepHandler = stepHandler else {
                    finish(with: .noStepHandler)
                    return
                }
                
                stepHandler(.chooseFactor(factors))
            }
            
        case .authenticatorEnrollmentData: fallthrough
        case .authenticatorVerificationData:
            guard let stepHandler = stepHandler else {
                finish(with: .noStepHandler)
                return
            }

            // Find the methods available to the user.
            let methods: [Authenticator.Method]
            methods = remediation.authenticators.flatMap({ authenticator in
                authenticator.methods ?? []
            })

            stepHandler(.chooseMethod(methods))

        case .enrollProfile:
            remediation["userProfile.firstName"]?.value = profile?[.firstName]
            remediation["userProfile.lastName"]?.value = profile?[.lastName]
            remediation["userProfile.email"]?.value = username
            remediation.proceed(completion: nil)

        default:
            finish(with: .cannotProceed)
        }
    }
}

// Utility functions to help return responses to the caller.
extension MultifactorLogin {
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
    
    func finish(with token: Token) {
        completion?(.success(token))
        completion = nil
    }
}
