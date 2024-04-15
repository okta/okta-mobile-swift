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
                    }
                }
                
                Button("Sign In") {
                    Task {
                        do {
                            status = try await flow.start(username, with: factor)
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
        }
    }
}
