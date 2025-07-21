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
import OktaIdxAuth
import AuthenticationServices

enum SigninError: Error {
    case genericError(message: String)
    case noClientConfiguration
    case cannotCompleteAuthorization(message: String)
    case stepUnsupported
    case invalidUrl
}

/// Signin wrapper that uses the Okta IDX client to step through the series
/// of remediation steps necessary to sign a user in.
public final class Signin: NSObject {
    private let storyboard: UIStoryboard
    private var completion: ((Result<Credential, Error>) -> Void)?
    private(set) var navigationController: UINavigationController?
    private(set) var authorizationContext: (any AuthorizationContext)?

    internal let flow: InteractionCodeFlow
    
    /// Initializes a signin instance with the given client configuration.
    /// - Parameter configuration: Client app configuration.
    init(using flow: InteractionCodeFlow) {
        self.flow = flow
        self.storyboard = UIStoryboard(name: "IDXSignin", bundle: Bundle(for: type(of: self)))

        super.init()
    }

    /// Begins the signin UI, presented from the given presenting view controller.
    /// - Parameter viewController: View controller to modally present the sign in navigation controller from.
    /// - Returns: Future to represent the completion of the signin process.
    public func signin(from viewController: UIViewController, completion: @escaping (Result<Credential, Error>) -> Void) {
        guard let controller = self.storyboard.instantiateViewController(identifier: "start") as? IDXStartViewController else {
            completion(.failure(SigninError.genericError(message: "Cannot find story board controller \"start\"")))
            return
        }
        
        controller.signin = self
        self.completion = completion
        
        let navigationController = UINavigationController(rootViewController: controller)
        self.navigationController = navigationController
        
        viewController.present(navigationController, animated: true, completion: nil)
    }
    
    /// Attempts to authorize the provided magic link, verifying the state matches the current session.
    /// - Parameter url: The magic link to authorize.
    public func authorize(magicLink url: URL) {
        guard let controller = navigationController?.topViewController as? IDXRemediationTableViewController else {
            return
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryArguments = components.queryItems?.reduce(into: [String:String](), { partialResult, item in
                  guard let value = item.value else { return }
                  partialResult[item.name] = value
              }),
              let otp = queryArguments["otp"],
              let state = queryArguments["state"]
        else {
            return
        }
        
        guard state == flow.context?.state else {
            let alert = UIAlertController(title: "Invalid magic link",
                                          message: "The state does not match",
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            navigationController?.topViewController?.present(alert, animated: true)
            return
        }
        
        controller.authorize(magicLink: otp)
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
            
        case .selectAuthenticatorAuthenticate, .selectAuthenticatorEnroll:
            return "Choose"
            
        case .launchAuthenticator:
            return "Launch Authenticator"
            
        case .cancel:
            return "Restart"
            
        case .unlockAccount:
            return "Unlock Account"

        case .challengeAuthenticator:
            switch option.authenticators.first?.type {
            case .securityKey:
                return "Sign In"
            default:
                return "Continue"
            }

        case .enrollAuthenticator:
            switch option.authenticators.first?.type {
            case .securityKey:
                return "Set Up"
            default:
                return "Continue"
            }

        default:
            return "Continue"
        }
    }

    /// Called by each view controller once their remediation step has been completed, allowing it to proceed to the next step of the workflow.
    /// - Parameter response: IDX response object received from the API.
    @MainActor
    func proceed(to response: Response) {
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
                    guard response.canRestart else { return }

                    Task { @MainActor in
                        do {
                            self.proceed(to: try await response.restart())
                        } catch {
                            self.failure(with: error)
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

        // If a native authorization controller is applicable to the contents of
        // this response, prepare the appropriate authorization requests.
        authorizationContext = authorizationContext(for: response)
        authorizationContext?.presentIfNeeded(userInitiated: false)
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

    func showError(_ error: Error, from viewController: UIViewController? = nil, recoverable: Bool = false) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.showError(error, from: viewController, recoverable: recoverable)
            }
            return
        }

        let viewController = viewController ?? navigationController?.topViewController

        let alert = UIAlertController(title: "Login error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        let parentController = navigationController?.presentingViewController
        if recoverable {
            viewController?.present(alert, animated: true)
        } else {
            viewController?.dismiss(animated: true) {
                parentController?.present(alert, animated: true) {
                    Task { @MainActor in
                        self.failure(with: error)
                    }
                }
            }
        }
    }

    /// Called by the signin view controllers when the Future should fail.
    /// - Parameter error: The error to pass to the future.
    @MainActor
    internal func failure(with error: Error) {
        navigationController?.dismiss(animated: true) {
            guard let completion = self.completion else { return }
            defer { self.completion = nil }
            completion(.failure(error))
        }
    }
    
    /// Called by the signin view controllers when the Future should succeed.
    /// - Parameter token: The token produced at the end of the signin process.
    @MainActor
    internal func success(with token: Token) {
        let credential: Credential
        do {
            credential = try Credential.store(token)
        } catch {
            failure(with: error)
            return
        }

        guard let completion = self.completion else { return }
        defer { self.completion = nil }

        Task { @MainActor in
            do {
                _ = try await credential.userInfo()
                self.navigationController?.dismiss(animated: true) {
                    completion(.success(credential))
                }
            } catch {
                self.failure(with: error)
            }
        }
    }
}

@MainActor
protocol AuthorizationContext {
    associatedtype Controller

    var controller: Controller { get }
    nonisolated var mode: AuthorizationContextMode { get }
    var state: AuthorizationContextState { get }

    func presentIfNeeded(userInitiated: Bool)
    func cancel()
}

enum AuthorizationContextMode {
    case automatic
    case userInitiated
}

enum AuthorizationContextState {
    case pending, presented, cancelled, registering, completed
}

extension Signin {
    @MainActor
    func authorizationContext(for response: Response) -> (any AuthorizationContext)? {
        if let context = PasskeyAuthorizationContext(self, response: response) {
            return context
        }

        return nil
    }

    @MainActor
    final class PasskeyAuthorizationContext: AuthorizationContext {
        nonisolated let mode: AuthorizationContextMode
        private(set) var state: AuthorizationContextState = .pending
        let controller: ASAuthorizationController
        nonisolated let webAuthnAuthenticate: WebAuthnAuthenticationCapability?
        nonisolated let webAuthnRegister: WebAuthnRegistrationCapability?

        init?(_ signin: Signin, response: Response) {
            var authorizationRequests = [ASAuthorizationRequest]()

            if let remediation = response.remediations[.challengeWebAuthnAutofillUIAuthenticator],
               let capability = remediation.webAuthnAuthentication
            {
                authorizationRequests.append(capability.createPlatformCredentialAssertionRequest())
                self.webAuthnAuthenticate = capability
                self.webAuthnRegister = nil
                self.mode = .automatic
            }

            else {
                self.mode = .userInitiated

                if let remediation = response.remediations[.challengeAuthenticator],
                   let capability = remediation.webAuthnAuthentication
                {
                    authorizationRequests.append(capability.createPlatformCredentialAssertionRequest())
                    authorizationRequests.append(capability.createSecurityKeyCredentialAssertionRequest())
                    self.webAuthnAuthenticate = capability
                } else {
                    self.webAuthnAuthenticate = nil
                }

                if let remediation = response.remediations[.enrollAuthenticator],
                   let capability = remediation.webAuthnRegistration
                {
                    authorizationRequests.append(capability.createPlatformRegistrationRequest())
                    authorizationRequests.append(capability.createSecurityKeyRegistrationRequest())
                    self.webAuthnRegister = capability
                } else {
                    self.webAuthnRegister = nil
                }
            }

            guard !authorizationRequests.isEmpty else {
                return nil
            }

            self.controller = ASAuthorizationController(authorizationRequests: authorizationRequests)
            self.controller.delegate = signin
            self.controller.presentationContextProvider = signin
        }

        deinit {
            if state == .presented {
                controller.cancel()
            }
        }

        func presentIfNeeded(userInitiated: Bool) {
            guard state == .pending else {
                return
            }

            if mode == .automatic && !userInitiated {
                controller.performAutoFillAssistedRequests()
            }

            else if mode == .userInitiated && userInitiated {
                controller.performRequests()
            }

            else {
                return
            }

            state = .presented
        }

        func cancel() {
            guard state == .presented else {
                return
            }

            controller.cancel()
            state = .cancelled
        }

        func complete(credential: any ASAuthorizationCredential) async throws -> Response {
            guard state == .presented else {
                throw SigninError.cannotCompleteAuthorization(message: "Authorization controller is not presented")
            }

            state = .registering
            let response: Response

            switch credential {
            case let credential as any ASAuthorizationPublicKeyCredentialRegistration:
                guard let webAuthnRegister else {
                    throw SigninError.cannotCompleteAuthorization(message: "No registration capability associated with this remediation")
                }

                response = try await webAuthnRegister.register(credential: credential)

            case let credential as any ASAuthorizationPublicKeyCredentialAssertion:
                guard let webAuthnAuthenticate else {
                    throw SigninError.cannotCompleteAuthorization(message: "No authentication capability associated with this remediation")
                }

                response = try await webAuthnAuthenticate.challenge(credential: credential)

            default:
                throw SigninError.cannotCompleteAuthorization(message: "Unsupported credential type \(type(of: credential))")
            }

            state = .completed
            return response
        }
    }
}

extension Signin: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        navigationController?.view.window ?? UIWindow()
    }
}

extension Signin: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithAuthorization authorization: ASAuthorization)
    {
        guard let passkeyContext = authorizationContext as? PasskeyAuthorizationContext,
              passkeyContext.controller == controller
        else {
            return
        }

        Task { @MainActor in
            do {
                proceed(to: try await passkeyContext.complete(credential: authorization.credential))
            } catch {
                showError(error)
            }
            self.authorizationContext = nil
        }
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: any Error)
    {
        guard let error = error as? ASAuthorizationError else {
            print("Unexpected authorization error: \(error.localizedDescription)")

            Task { @MainActor in
                showError(error)
            }
            return
        }

        guard let passkeyContext = authorizationContext as? PasskeyAuthorizationContext
        else {
            return
        }

        if passkeyContext.controller == controller {
            authorizationContext = nil
        }

        if error.code != .canceled {
            Task { @MainActor in
                showError(error)
            }
        }
    }
}
