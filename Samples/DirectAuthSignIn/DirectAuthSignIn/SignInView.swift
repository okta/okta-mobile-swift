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

struct SignInView: View {
    let flow: DirectAuthenticationFlow?
    
    @State var status: DirectAuthenticationFlow.Status?
    @State var error: (any Error)?
    @State var hasError: Bool = false

    enum Factor {
        case password, otp, oob
        
        var title: String {
            switch self {
            case .password: return "Password"
            case .otp: return "One-Time Code"
            case .oob: return "Push Notification"
            }
        }
        
        static let primaryFactors: [Factor] = [.password, .otp, .oob]
        static let secondaryFactors: [Factor] = [.otp, .oob]
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Direct Authentication Sign In")
                    .font(.title)
                
                if let flow = flow {
                    if let status = status {
                        SecondaryView(flow: flow,
                                      status: status,
                                      error: $error,
                                      hasError: $hasError)
                    } else {
                        PrimaryView(flow: flow,
                                    status: $status,
                                    error: $error,
                                    hasError: $hasError)
                    }
                } else {
                    UnconfiguredView()
                }
            }.padding()

            Spacer()
            HStack {
                Text("Client ID:")
                if let clientId = flow?.client.configuration.clientId {
                    Text(clientId)
                        .accessibilityIdentifier("client_id_label")
                } else {
                    Text("Not configured")
                }
            }
        }
        .alert("Error", isPresented: $hasError) {
            Button("OK") {}
        } message: {
            if let description = error?.localizedDescription {
                Text(description)
            } else {
                EmptyView()
            }
        }
        .navigationTitle("Direct Authentication")
    }
}

// swiftlint:disable force_unwrapping
struct SignInViewPrimary_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(flow: .init(issuer: URL(string: "https://example.com")!,
                               clientId: "abcd123",
                               scopes: "openid profile"))
    }
}

struct SignInViewSecondary_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(flow: .init(issuer: URL(string: "https://example.com")!,
                               clientId: "abcd123",
                               scopes: "openid profile"),
                   status: .mfaRequired(.init(supportedChallengeTypes: [],
                                              mfaToken: "abcd1234")))
    }
}
// swiftlint:enable force_unwrapping
