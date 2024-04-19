//
// Copyright (c) 2023-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import SwiftUI
import OktaDirectAuth
import AuthenticationServices

extension SignInView {
    struct PrimaryView: View {
        let flow: DirectAuthenticationFlow
        
        @Binding var status: DirectAuthenticationFlow.Status?
        @Binding var error: Error?
        @Binding var hasError: Bool
        
        @State var username: String = ""
        @State var password: String = ""
        @State var oneTimeCode: String = ""
        @State var selectedFactor: SignInView.Factor = .password
        
        var factor: DirectAuthenticationFlow.PrimaryFactor {
            switch selectedFactor {
            case .password:
                return .password(password)
            case .otp:
                return .otp(code: oneTimeCode)
            case .oob:
                return .oob(channel: .push)
            case .webauthn:
                return .webAuthn
            }
        }
        
        var body: some View {
            VStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username:")
                    TextField("jane.doe@example.com", text: $username)
                        .id("username_field")
                        .accessibilityIdentifier("username_field")
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                        .padding(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.secondary, lineWidth: 1)
                        }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Picker(selection: $selectedFactor, label: EmptyView()) {
                        ForEach(SignInView.Factor.primaryFactors, id: \.self) {
                            Text($0.title)
                        }
                    }.pickerStyle(.menu)
                        .accessibilityIdentifier("factor_type_button")
                        .padding(.horizontal, -10)
                        .padding(.vertical, -4)
                    
                    switch selectedFactor {
                    case .password:
                        SecureField("Password", text: $password)
                            .id("password_button")
                            .textContentType(.password)
                            .accessibilityIdentifier("password_button")
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.secondary, lineWidth: 1)
                            }
                    case .otp:
                        TextField("123456", text: $oneTimeCode)
                            .id("one_time_code_button")
                            .textContentType(.oneTimeCode)
                            .accessibilityIdentifier("one_time_code_button")
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.secondary, lineWidth: 1)
                            }
                    case .oob: EmptyView()
                    case .webauthn: EmptyView()
                    }
                }
                
                Button("Sign In") {
                    Task {
                        do {
                            status = try await flow.start(username, with: factor)
                            if case let .success(token) = status {
                                Credential.default = try Credential.store(token)
                            }
                            if case let .webAuthn(context) = status {
                                let request = context.request
                                let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "https://passkeyshack.clouditude.com")
                                let challenge = request.publicKey.challenge.data(using: .utf8)!
                                let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
                                let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
                                let response = try await withCheckedThrowingContinuation { continuation in
                                    let authCallback = AppleAuthCallback(checkedContinuation: continuation)
                                    authController.delegate = authCallback
                                    authController.performRequests()
                                }
                                let challengeStatus = status!
                                status = try await flow.resume(challengeStatus, with: .webAuthnAssertion(response))

                                if case let .success(token) = status {
                                    Credential.default = try Credential.store(token)
                                }
                            }
                        } catch {
                            self.error = error
                            self.hasError = true
                        }
                    }
                }
                .accessibilityIdentifier("signin_button")
                .font(.headline)
                .buttonStyle(.borderedProminent)
            }.padding()
        }
    }
}

class AppleAuthCallback: NSObject, ASAuthorizationControllerDelegate {
    public let continuation: CheckedContinuation<WebAuthn.AuthenticatorAssertionResponse, Error>
    
    init(checkedContinuation: CheckedContinuation<WebAuthn.AuthenticatorAssertionResponse, Error>) {
        continuation = checkedContinuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            guard let signature = credentialAssertion.signature else {
                print("Missing signature")
                continuation.resume(throwing: NSError())
                return
            }
            guard let authenticatorData = credentialAssertion.rawAuthenticatorData else {
                print("Missing authenticatorData")
                continuation.resume(throwing: NSError())
                return
            }
            let clientDataJSON = credentialAssertion.rawClientDataJSON
            let credentialId = credentialAssertion.credentialID
            let webAuthnAssertion = WebAuthn.AuthenticatorAssertionResponse(
                clientDataJSON: String(decoding: clientDataJSON, as: UTF8.self),
                authenticatorData: String(decoding: authenticatorData, as: UTF8.self),
                signature: String(decoding: signature, as: UTF8.self),
                userHandle: nil
            )
            continuation.resume(returning: webAuthnAssertion)
        default:
            continuation.resume(throwing: NSError())
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
