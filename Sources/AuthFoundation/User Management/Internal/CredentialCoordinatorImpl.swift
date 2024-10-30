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
import OktaUtilities
import OktaConcurrency
import OktaConcurrency

#if os(Linux)
import FoundationNetworking
#endif

@HasLock
final class CredentialCoordinatorImpl: Sendable, CredentialCoordinator {
    @Synchronized
    var credentialDataSource: any CredentialDataSource {
        didSet {
            _credentialDataSource.delegate = self
        }
    }
    
    @Synchronized
    var tokenStorage: any TokenStorage {
        didSet {
            _tokenStorage.delegate = self
            
            // Reset the default credential, allowing for the next request
            // for it to fetch the value from token storage.
            _default = nil
        }
    }
    
    nonisolated(unsafe) private var _default: Credential?
    var `default`: Credential? {
        get {
            withLock {
                try? _getDefaultCredential()
            }
        }
        set {
            withLock {
                try? _setDefaultCredential(newValue)
            }
        }
    }
    
    public var allIDs: [String] {
        withLock {
            _tokenStorage.allIDs
        }
    }
    
    func store(token: Token, security: [Credential.Security]) throws -> Credential {
        try withLock {
            let wasEmpty = _tokenStorage.allIDs.isEmpty
            try _tokenStorage.add(token: token, security: security)
            if wasEmpty {
                try _tokenStorage.setDefaultTokenID(token.id)
            }
            
            let credential = _credentialDataSource.credential(for: token, coordinator: self)
            if wasEmpty {
                try _setDefaultCredential(credential)
            }
            
            return credential
        }
    }
    
    func with(id: String, prompt: String?, authenticationContext: (any TokenAuthenticationContext)?) throws -> Credential? {
        try withLock {
            try _with(id: id, prompt: prompt, authenticationContext: authenticationContext)
        }
    }
    
    func find(where expression: @escaping (Token.Metadata) -> Bool,
              prompt: String? = nil,
              authenticationContext: (any TokenAuthenticationContext)? = nil) throws -> [Credential]
    {
        try withLock {
            try _tokenStorage.allIDs
                .map(_tokenStorage.metadata(for:))
                .filter(expression)
                .compactMap({ metadata in
                    try self._with(id: metadata.id, prompt: prompt, authenticationContext: authenticationContext)
                })
        }
    }
    
    func remove(credential: Credential) throws {
        try withLock {
            let isDefault = _tokenStorage.defaultTokenID == credential.token.id

            _credentialDataSource.remove(credential: credential)
            try _tokenStorage.remove(id: credential.id)
            
            if isDefault {
                try _tokenStorage.setDefaultTokenID(nil)
                _default = nil
            }
        }
    }
    
    static func defaultTokenStorage() -> any TokenStorage {
        #if canImport(Darwin)
        KeychainTokenStorage()
        #else
        UserDefaultsTokenStorage()
        #endif
    }
    
    static func defaultCredentialDataSource() -> any CredentialDataSource {
        DefaultCredentialDataSource()
    }
    
    let notificationCenter: NotificationCenter
    
    init(tokenStorage: any TokenStorage = defaultTokenStorage(),
         credentialDataSource: any CredentialDataSource = defaultCredentialDataSource(),
         notificationCenter: NotificationCenter = .default)
    {
        self.notificationCenter = notificationCenter
        _credentialDataSource = credentialDataSource
        _tokenStorage = tokenStorage

        _credentialDataSource.delegate = self
        _tokenStorage.delegate = self
    }
    
    func observe(oauth2 client: OAuth2Client) {
        client.add(delegate: self)
        
        // Inform the default time coordinator of responses from the API client
        if let timeCoordinator = Date.coordinator as? DefaultTimeCoordinator {
            client.add(delegate: timeCoordinator)
        }
    }

    // MARK: Private implementations
    
    private func _getDefaultCredential() throws -> Credential? {
        guard _default == nil else {
            return _default
        }
        
        do {
            if let defaultTokenId = _tokenStorage.defaultTokenID {
                var context: (any TokenAuthenticationContext)?
                #if canImport(LocalAuthentication) && !os(tvOS)
                context = Credential.Security.standard.context
                #endif
                
                let token = try _tokenStorage.get(token: defaultTokenId,
                                                  prompt: nil,
                                                  authenticationContext: context)
                _default = _credentialDataSource.credential(for: token, coordinator: self)
            }
        } catch {
            // Placeholder for when logging is added in a future release
            print("Error occurred while loading the default credential: \(error)")
        }
        
        return _default
    }

    private func _setDefaultCredential(_ credential: Credential?) throws {
        // Use private instance properties to avoid deadlocks.
        do {
            if let token = credential?.token,
               !_tokenStorage.allIDs.contains(token.id)
            {
                try _tokenStorage.add(token: token,
                                      security: Credential.Security.standard)
            }
            try _tokenStorage.setDefaultTokenID(credential?.id)
            
            _default = credential
            
            DispatchQueue.main.async {
                self.notificationCenter.post(name: .defaultCredentialChanged,
                                             object: credential)
            }
        } catch {
            // Placeholder for when logging is added in a future release
            print("Error occurred while setting the default credential: \(error)")
        }
    }

    private func _with(id: String, prompt: String?, authenticationContext: (any TokenAuthenticationContext)?) throws -> Credential? {
        let token = try _tokenStorage.get(token: id,
                                          prompt: prompt,
                                          authenticationContext: authenticationContext)
        return _credentialDataSource.credential(for: token,
                                                coordinator: self)
    }
    
}

extension CredentialCoordinatorImpl: OAuth2ClientDelegate {
    func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        guard let newToken = newToken else {
            return
        }

        do {
            try tokenStorage.update(token: newToken, security: nil)
        } catch {
            print("Error happened refreshing: \(error)")
        }
    }
}

extension CredentialCoordinatorImpl: TokenStorageDelegate {
    func token(storage: any TokenStorage, defaultChanged id: String?) {
        // Almost all default ID changes will be triggered from the Credential Coordinator.
        // In the rare event that the underlying value is changed from some other means,
        // this operation will ensure the statei of this class will remain consistent.
        withLock {
            // Ensure the new token is indeed different from the local default.
            if _default?.id != id {
                _default = nil
            }
        }
    }
    
    func token(storage: any TokenStorage, added id: String, token: Token) {
    }
    
    func token(storage: any TokenStorage, removed id: String) {
    }
    
    func token(storage: any TokenStorage, replaced id: String, with newToken: Token) {
        // Doing nothing with this, for now...
    }
}

extension CredentialCoordinatorImpl: CredentialDataSourceDelegate {
    func credential(dataSource: any CredentialDataSource, created credential: Credential) {
        credential.coordinator = self
        
        self.notificationCenter.post(name: .credentialCreated, object: credential)
    }
    
    func credential(dataSource: any CredentialDataSource, removed credential: Credential) {
        credential.coordinator = nil

        self.notificationCenter.post(name: .credentialRemoved, object: credential)
    }
    
    func credential(dataSource: any CredentialDataSource, updated credential: Credential) {
    }
}
