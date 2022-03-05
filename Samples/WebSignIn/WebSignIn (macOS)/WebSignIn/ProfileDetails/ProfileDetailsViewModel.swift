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

import Foundation
import Combine
import WebAuthenticationUI

final class ProfileDetailsViewModel: ObservableObject {
    var givenName: String? { userInfo?.givenName }
    var familyName: String? { userInfo?.familyName }
    var userLocale: String? { userInfo?.userLocale?.identifier }
    var timezone: String? { userInfo?.timeZone?.identifier }
    var username: String? { userInfo?.preferredUsername }
    var userId: String? { userInfo?.subject }
    var createdAt: String? {
        userInfo?.updatedAt.flatMap {
            self.dateFormatter.string(from: $0)
        }
    }
    
    @Published private(set) var signedIn: Bool = true
    @Published private(set) var loadingUserInfo: Bool = true
    
    @Published private var userInfo: UserInfo?
    @Published private var credential: Credential? {
        didSet {
            if credential != oldValue {
                loadUserInfo()
            }
        }
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long
        
        return dateFormatter
    }()
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(credential: Credential?) {
        self.credential = credential
        
        $credential
            .map { $0 != nil }
            .assign(to: &$signedIn)
        
        $credential
            .sink { self.userInfo = $0?.userInfo }
            .store(in: &cancellableSet)
        
        $userInfo
            .map { $0 == nil }
            .assign(to: &$loadingUserInfo)
        
        NotificationCenter.default
            .publisher(for: .defaultCredentialChanged, object: nil)
            .compactMap { $0.object as? Credential }
            .sink { self.credential = $0 }
            .store(in: &cancellableSet)
    }
    
    func removeUserInfo() {
        try? credential?.remove()
    }
    
    func revokeTokens() {
        credential?.revoke(type: .accessToken) { _ in
            DispatchQueue.main.async {
                self.credential = nil
            }
        }
    }
    
    private func loadUserInfo() {
        if credential == nil {
            return
        }
        
        credential?.userInfo { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userInfo):
                    self?.userInfo = userInfo
                case .failure:
                    self?.credential = nil
                }
            }
        }
    }
}
