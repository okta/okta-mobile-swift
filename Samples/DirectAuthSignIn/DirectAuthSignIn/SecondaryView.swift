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
    struct SecondaryView: View {
        let flow: DirectAuthenticationFlow
        
        @State var status: DirectAuthenticationFlow.Status
        @State var selectedFactor: SignInView.Factor = .otp
        @State var oneTimeCode: String = ""
        
        var factor: DirectAuthenticationFlow.SecondaryFactor? {
            switch selectedFactor {
            case .otp:
                return .otp(code: oneTimeCode)
            case .oob:
                return .oob(channel: .push)
            case .password:
                return nil
            }
        }
        
        @Binding var error: Error?
        @Binding var hasError: Bool
        
        var body: some View {
            VStack {
                Text("Please authenticate using an additional factor.")
                    .padding(25)
                
                VStack(alignment: .leading, spacing: 1) {
                    Picker(selection: $selectedFactor, label: EmptyView()) {
                        ForEach(SignInView.Factor.secondaryFactors, id: \.self) {
                            Text($0.title)
                        }
                    }.pickerStyle(.menu)
                        .accessibilityIdentifier("factor_type_button")
                        .padding(.horizontal, -10)
                        .padding(.vertical, -4)
                    
                    if selectedFactor == .otp {
                        TextField("123456", text: $oneTimeCode)
                            .textContentType(.oneTimeCode)
                            .accessibilityIdentifier("one_time_code_button")
                            .padding(10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.secondary, lineWidth: 1)
                            }
                    }
                    
                    if let factor = factor {
                        Button("Continue") {
                            Task {
                                do {
                                    status = try await flow.resume(status, with: factor)
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
                    }
                }.padding()
            }
        }
    }
}
