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
import WebAuthenticationUI

enum AppSettings {
    enum SignInView {
        static let height: Double = 400
        static let width: Double = 500
    }
}

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @Binding private var signedIn: Bool
    @State private var cancellableSet: Set<AnyCancellable> = []
    
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
                viewModel.signIn()
            }
            .disabled(!viewModel.isConfigured)
            .alert(isPresented: $viewModel.presentError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.signInError?.localizedDescription ?? "An unknown error occurred")
                )
            }
            .padding()
            
            Toggle("Ephemeral Session", isOn: $viewModel.ephemeralSession)
            
            Spacer()
            
            Text(viewModel.isConfigured ? "Client ID: \(viewModel.clientID ?? "N/A")" : "Not configured")
                .font(.caption)
                .padding()
        }.onAppear {
            subscribe()
        }
    }
    
    func subscribe() {
        viewModel.$signedIn
            .sink { self.$signedIn.wrappedValue = $0 }
            .store(in: &self.cancellableSet)
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
