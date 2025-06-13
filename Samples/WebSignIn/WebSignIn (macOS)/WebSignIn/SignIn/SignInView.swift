//
// Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import Combine
import BrowserSignin
import AuthenticationServices

enum AppSettings {
    enum SignInView {
        static let height: Double = 400
        static let width: Double = 500
    }
}

struct SignInView: View {
    @Binding private var signedIn: Bool
    @State var ephemeralSession: Bool = false
    @State var signInError: (any Error)?
    @State var hasError: Bool = false
    @State var clientId: String?

    init(signedIn: Binding<Bool>) {
        self._signedIn = signedIn
    }
    
    var body: some View {
        VStack {
            Text("Okta Web Sign In")
                .font(.largeTitle)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text("Have an account?")
            
            Button("Sign In") {
                guard let auth = BrowserSignin.shared else { return }
                auth.ephemeralSession = ephemeralSession
                Task {
                    do {
                        let token = try await auth.signIn(from: ASPresentationAnchor())
                        try Credential.store(token)
                        signedIn = true
                    } catch {
                        signInError = error
                        signedIn = false
                    }
                }
            }
            .disabled(clientId == nil)
            .alert(isPresented: $hasError) {
                Alert(
                    title: Text("Error"),
                    message: Text(signInError?.localizedDescription ?? "An unknown error occurred")
                )
            }
            .padding()
            
            Toggle("Ephemeral Session", isOn: $ephemeralSession)

            Spacer()

            HStack {
                Text("Client ID:")
                Text(clientId ?? "Not configured")
                    .font(.caption)
                    .padding()
            }
            .onAppear {
                Task {
                    clientId = await BrowserSignin.shared?.signInFlow.client.configuration.clientId
                }
            }
        }
    }

    func signIn() async {
        guard let auth = BrowserSignin.shared else { return }

        auth.ephemeralSession = ephemeralSession
        do {
            let token = try await auth.signIn(from: ASPresentationAnchor())
            try Credential.store(token)
            signedIn = true
        } catch {
            signInError = error
            signedIn = false
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(signedIn: .constant(false))
            .frame(minWidth: AppSettings.SignInView.width,
                   minHeight: AppSettings.SignInView.height)
    }
}
#endif
