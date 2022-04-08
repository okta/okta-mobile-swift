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

import Combine
import SwiftUI

struct ProfileDetailsView: View {
    @StateObject private var viewModel: ProfileDetailsViewModel
    @Binding private var signedIn: Bool
    @State private var presentSignOutAlert: Bool = false
    @State private var cancellableSet: Set<AnyCancellable> = []
    
    init(viewModel: ProfileDetailsViewModel, signedIn: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._signedIn = signedIn
    }
    
    var body: some View {
        VStack {
            if viewModel.loadingUserInfo {
                ProgressView()
            } else {
                Form {
                    ProfileDetailItemView(leading: "Given name", trailing: viewModel.givenName)
                    ProfileDetailItemView(leading: "Family name", trailing: viewModel.familyName)
                    ProfileDetailItemView(leading: "Locale", trailing: viewModel.userLocale)
                    ProfileDetailItemView(leading: "Timezone", trailing: viewModel.timezone)
                    ProfileDetailItemView(leading: "Username", trailing: viewModel.username)
                    ProfileDetailItemView(leading: "User ID", trailing: viewModel.userId)
                    ProfileDetailItemView(leading: "Created at", trailing: viewModel.createdAt)
                }
            }
            
            Button("Sign Out") {
                presentSignOutAlert = true
            }
            .alert(isPresented: $presentSignOutAlert) {
                Alert(title: Text("Sign out"),
                      primaryButton: .default(Text("Yes"),
                                              action: {
                    viewModel.revokeTokens()
                }), secondaryButton: .cancel())
            }
            .padding()
        }.onAppear {
            subscribe()
        }
    }
    
    private func subscribe() {
        viewModel.$signedIn
            .sink {
            self.$signedIn.wrappedValue = $0
            }
        .store(in: &self.cancellableSet)
    }
}

#if DEBUG
struct ProfileDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileDetailsView(viewModel: ProfileDetailsViewModel(credential: .default), signedIn: .constant(true))
            .frame(minWidth: AppSettings.SignInView.width,
                   minHeight: AppSettings.SignInView.height)
    }
}
#endif
