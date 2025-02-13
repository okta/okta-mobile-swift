//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaDirectAuth

extension SignInView {
    struct ContinuationView: View {
        let flow: DirectAuthenticationFlow
        
        @State var status: DirectAuthenticationFlow.Status
        @State var selectedFactor: SignInView.Factor = .code
        @State var verificationCode: String = ""
        
        var factor: DirectAuthenticationFlow.ContinuationFactor? {
            switch selectedFactor {
            case .code:
                return .prompt(code: verificationCode)
            default:
                return nil
            }
        }
        
        var continuationType: DirectAuthenticationFlow.ContinuationType? {
            guard case let .continuation(continuationType) = status else {
                return nil
            }
            
            return continuationType
        }
        
        @Binding var error: Error?
        @Binding var hasError: Bool
        
        var body: some View {
            switch continuationType {
            case .webAuthn(_):
                Text("Ignoring WebAuthn type")
                    .padding()
            case .transfer(_, let code):
                VStack(alignment: .center, spacing: 8) {
                    Text("Use the verification code")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    if #available(iOS 16.0, *) {
                        Text(code)
                            .font(.system(.largeTitle, design: .monospaced, weight: .black))
                            .multilineTextAlignment(.center)
                    } else {
                        Text(code)
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                    }
                    ProgressView()
                        .onAppear {
                            Task {
                                do {
                                    status = try await flow.resume(with: .transfer)
                                    if case let .success(token) = status {
                                        Credential.default = try Credential.store(token)
                                    }
                                } catch {
                                    self.error = error
                                    self.hasError = true
                                }
                            }
                        }
                }
            case .prompt(_):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification code:")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    TextField("123456", text: $verificationCode)
                        .textContentType(.oneTimeCode)
                        .accessibilityIdentifier("verification_code_button")
                        .padding(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.secondary, lineWidth: 1)
                        }
                    
                    Button("Continue") {
                        Task {
                            do {
                                status = try await flow.resume(with: .prompt(code: verificationCode))
                                if case let .success(token) = status {
                                    Credential.default = try Credential.store(token)
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
            case nil:
                Text("Invalid status type")
                    .padding()
            }
        }
    }
}

extension DirectAuthenticationFlow.ContinuationType {
    static let previewTransfer: Self = .transfer(
        .init(oobResponse: .init(oobCode: "OOBCODE", expiresIn: 600, interval: 10, channel: .push, bindingMethod: .transfer), mfaContext: nil),
        code: "73")
    static let previewPrompt: Self = .prompt(.init(oobResponse: .init(oobCode: "OOBCODE", expiresIn: 600, interval: 10, channel: .push, bindingMethod: .transfer), mfaContext: nil))
}

#Preview {
    struct Preview: View {
        var flow = DirectAuthenticationFlow(
            // swiftlint:disable:next force_unwrapping
            issuerURL: URL(string: "https://example.com/")!,
            clientId: "clientid",
            scope: "scopes")
        @State var error: Error?
        @State var hasError: Bool = false
        @State var continuationType: DirectAuthenticationFlow.ContinuationType = .previewPrompt
        
        var body: some View {
            SignInView.ContinuationView(
                flow: flow,
                status: .continuation(continuationType),
                error: $error,
                hasError: $hasError)
        }
    }

    return Preview()
}
