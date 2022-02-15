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

#if os(Linux)
import FoundationNetworking
#endif

class CredentialCoordinatorImpl: CredentialCoordinator {
    var credentialDataSource: CredentialDataSource {
        didSet {
            credentialDataSource.delegate = self
        }
    }
    
    var tokenStorage: TokenStorage {
        didSet {
            tokenStorage.delegate = self
            
            if let defaultToken = tokenStorage.defaultToken {
                _default = credentialDataSource.credential(for: defaultToken, coordinator: self)
            } else {
                _default = nil
            }
        }
    }
        
    private var _default: Credential?
    var `default`: Credential? {
        get { _default }
        set { tokenStorage.defaultToken = newValue?.token }
    }
    
    public var allCredentials: [Credential] {
        tokenStorage.allTokens.map { credentialDataSource.credential(for: $0, coordinator: self) }
    }

    func `for`(token: Token) -> Credential {
        try? tokenStorage.add(token: token)
        return credentialDataSource.credential(for: token, coordinator: self)
    }
    
    func remove(credential: Credential) throws {
        credentialDataSource.remove(credential: credential)
        try tokenStorage.remove(token: credential.token)
    }
    
    static func defaultTokenStorage() -> TokenStorage {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
        KeychainTokenStorage()
        #else
        UserDefaultsTokenStorage()
        #endif
    }
    
    static func defaultCredentialDataSource() -> CredentialDataSource {
        DefaultCredentialDataSource()
    }
    
    init(tokenStorage: TokenStorage = defaultTokenStorage(),
         credentialDataSource: CredentialDataSource = defaultCredentialDataSource())
    {
        self.credentialDataSource = credentialDataSource
        self.tokenStorage = tokenStorage

        self.credentialDataSource.delegate = self
        self.tokenStorage.delegate = self

        if let defaultToken = tokenStorage.defaultToken {
            _default = credentialDataSource.credential(for: defaultToken, coordinator: self)
        }
        
        self.observer = NotificationCenter
            .default
            .addObserver(forName: .oauth2ClientCreated,
                         object: nil,
                         queue: nil) { [weak self] notification in
                self?.received(notification: notification)
            }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer as Any)
        }
    }
    
    private var observer: NSObjectProtocol?
    private func received(notification: Notification) {
        switch notification.name {
        case .oauth2ClientCreated:
            guard let client = notification.object as? OAuth2Client else { break }
            client.add(delegate: self)
        default: break
        }
    }
}

extension CredentialCoordinatorImpl: OAuth2ClientDelegate {
    func api(client: APIClient, didSend request: URLRequest, received error: APIClientError) {
        print("Error happened: \(error)")
    }

    func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        guard let newToken = newToken else {
            return
        }

        do {
            try tokenStorage.replace(token: token, with: newToken)
        } catch {
            print("Error happened refreshing: \(error)")
        }
    }
}

extension CredentialCoordinatorImpl: TokenStorageDelegate {
    func token(storage: TokenStorage, defaultChanged token: Token?) {
        guard _default?.token != token else { return }

        if let token = token {
            _default = credentialDataSource.credential(for: token, coordinator: self)
        } else {
            _default = nil
        }

        NotificationCenter.default.post(name: .defaultCredentialChanged,
                                        object: _default)
    }
    
    func token(storage: TokenStorage, added token: Token?) {
    }
    
    func token(storage: TokenStorage, removed token: Token?) {
    }
    
    func token(storage: TokenStorage, replaced oldToken: Token, with newToken: Token) {
        guard credentialDataSource.hasCredential(for: oldToken) else { return }
        
        // Doing nothing with this, for now...
    }
    
}

extension CredentialCoordinatorImpl: CredentialDataSourceDelegate {
    func credential(dataSource: CredentialDataSource, created credential: Credential) {
        credential.coordinator = self
        
        NotificationCenter.default.post(name: .credentialCreated, object: credential)
    }
    
    func credential(dataSource: CredentialDataSource, removed credential: Credential) {
        credential.coordinator = nil

        NotificationCenter.default.post(name: .credentialRemoved, object: credential)
    }
    
    func credential(dataSource: CredentialDataSource, updated credential: Credential) {
    }
}
