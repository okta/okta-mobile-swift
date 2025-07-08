/*
 * Copyright (c) 2025-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

extension Signin {
    public func authorizationController(with requests: [ASAuthorizationRequest], using remediation: Remediation?) -> ASAuthorizationController {
        authController?.cancel()

        let authController = ASAuthorizationController(authorizationRequests: requests)
        authController.delegate = self
        authController.presentationContextProvider = self

        self.authController = authController
        self.authRemediationOption = remediation
        return authController
    }

    private func register(credential: any ASAuthorizationPublicKeyCredentialRegistration, completion: @escaping () -> Void) {
        Task { @MainActor in
            guard let capability = authRemediationOption?.webAuthnRegistration
            else {
                failure(with: SigninError.cannotCompleteAuthorization(message: "No WebAuthn registration capability"))
                return
            }

            do {
                proceed(to: try await capability.register(credential: credential))
            } catch {
                failure(with: error)
            }
            completion()
        }
    }

    private func register(credential: any ASAuthorizationPublicKeyCredentialAssertion, completion: @escaping () -> Void) {
        Task { @MainActor in
            guard let capability = authRemediationOption?.webAuthnAuthentication
            else {
                failure(with: SigninError.cannotCompleteAuthorization(message: "No WebAuthn registration capability"))
                return
            }

            do {
                proceed(to: try await capability.challenge(credential: credential))
            } catch {
                failure(with: error)
            }
            completion()
        }
    }

    private func register(credential: any ASAuthorizationCredential, completion: @escaping () -> Void) {
        switch credential {
        case let credential as any ASAuthorizationPublicKeyCredentialRegistration:
            register(credential: credential, completion: completion)
        case let credential as any ASAuthorizationPublicKeyCredentialAssertion:
            register(credential: credential, completion: completion)
        default:
            Task { @MainActor in
                failure(with: SigninError.cannotCompleteAuthorization(message: "Unsupported credential type \(type(of: credential))"))
                completion()
            }
        }
    }

    private func prepareAutoFillAssistedPasskeySignIn(remediation: Remediation) {
        guard remediation.type == .challengeWebAuthnAutofillUIAuthenticator,
              let webAuthnAuthentication = remediation.webAuthnAuthentication
        else {
            return
        }

        authorizationController(
            with: [
                webAuthnAuthentication.createPlatformCredentialAssertionRequest()
            ],
            using: remediation)
        .performAutoFillAssistedRequests()
    }

    private func cancelAutoFillAssistedPasskeySignIn() {
        guard authRemediationOption?.type == .challengeWebAuthnAutofillUIAuthenticator,
              let authController
        else {
            return
        }

        authController.cancel()
        self.authController = nil
        self.authRemediationOption = nil
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
        guard controller == authController else {
            return
        }

        register(credential: authorization.credential) { [self] in
            self.authController = nil
            self.authRemediationOption = nil
        }
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: any Error)
    {
        authController = nil
        authRemediationOption = nil

        guard let error = error as? ASAuthorizationError else {
            print("Unexpected authorization error: \(error.localizedDescription)")
            return
        }

        if error.code == .canceled {
            print("Request canceled.")
        }

        else {
            print("Authorization error: \(error.userInfo)")
            Task { @MainActor in
                showError(error)
            }
        }
    }
}

extension Signin: InteractionCodeFlowDelegate {
    public func authenticationStarted<Flow>(flow: Flow) {
    }

    public func authenticationFinished<Flow>(flow: Flow) {
    }

    public func authenticationStarted<Flow>(flow: Flow) where Flow : OktaIdxAuth.InteractionCodeFlow {
    }

    public func authenticationFinished<Flow>(flow: Flow) where Flow : OktaIdxAuth.InteractionCodeFlow {
    }

    public func authenticationStarted(flow: any AuthenticationFlow) {
    }

    public func authenticationFinished(flow: any AuthenticationFlow) {
    }

    public func authentication<Flow>(flow: Flow, received error: OktaIdxAuth.InteractionCodeFlowError) where Flow : OktaIdxAuth.InteractionCodeFlow {
    }

    public func authentication<Flow>(flow: Flow, received token: AuthFoundation.Token) {
    }

    public func authentication<Flow>(flow: Flow, received response: OktaIdxAuth.Response) where Flow : OktaIdxAuth.InteractionCodeFlow {
        // If a passkey autofill remediation is encountered, proactively initiate an autofill passkey sign-in.
        if let remediation = response.remediations[.challengeWebAuthnAutofillUIAuthenticator] {
            if authController != nil,
               authRemediationOption?.type == .challengeWebAuthnAutofillUIAuthenticator
            {
                cancelAutoFillAssistedPasskeySignIn()
            }

            prepareAutoFillAssistedPasskeySignIn(remediation: remediation)
        }
    }

    public func authentication<Flow>(flow: Flow, received token: AuthFoundation.Token) where Flow : OktaIdxAuth.InteractionCodeFlow {
    }

    public func authentication<Flow>(flow: Flow, received error: AuthFoundation.OAuth2Error) {
    }
}
