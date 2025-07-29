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

#if os(Linux) || os(Android)
import FoundationNetworking
#endif

final class CredentialCoordinatorImpl: CredentialCoordinator {
    private var _credentialDataSource: (any CredentialDataSource)?
    private var _tokenStorage: (any TokenStorage)?

    nonisolated init() {}

    @CredentialActor
    var credentialDataSource: any CredentialDataSource {
        get {
            if let credentialDataSource = _credentialDataSource {
                return credentialDataSource
            }

            let result = Credential.providers.defaultCredentialDataSource()
            _credentialDataSource = result
            _credentialDataSource?.delegate = self
            return result
        }
        set {
            _credentialDataSource = newValue
            _credentialDataSource?.delegate = self
        }
    }

    @CredentialActor
    var tokenStorage: any TokenStorage {
        get {
            if let tokenStorage = _tokenStorage {
                return tokenStorage
            }

            let result = Credential.providers.defaultTokenStorage()
            _tokenStorage = result
            _tokenStorage?.delegate = self
            return result
        }
        set {
            _tokenStorage = newValue
            _tokenStorage?.delegate = self
            _default = _fetchDefaultCredential()
        }
    }

    private func _fetchDefaultCredential() -> Credential? {
        guard let tokenStorage = _tokenStorage,
              let credentialDataSource = _credentialDataSource
        else {
            return nil
        }

        return try? CredentialCoordinatorImpl.defaultCredential(
            tokenStorage: tokenStorage,
            credentialDataSource: credentialDataSource,
            coordinator: self)
    }

    private lazy var _default: Credential? = {
        do {
            return try CredentialCoordinatorImpl.defaultCredential(
                tokenStorage: tokenStorage,
                credentialDataSource: credentialDataSource,
                coordinator: self)
        } catch {
            // Placeholder for when logging is added in a future release
            return nil
        }
    }()

    @CredentialActor
    var `default`: Credential? {
        get { _default }
        set {
            do {
                if let token = newValue?.token,
                   !tokenStorage.allIDs.contains(token.id)
                {
                    try tokenStorage.add(token: token,
                                         metadata: Token.Metadata(id: token.id),
                                         security: Credential.Security.standard)
                }

                try tokenStorage.setDefaultTokenID(newValue?.id)
            } catch {
                print("Could not set a new default credential: \(error)")
            }
        }
    }
    
    @CredentialActor
    public var allIDs: [String] {
        tokenStorage.allIDs
    }
    
    @CredentialActor
    func store(token: Token, tags: [String: String], security: [Credential.Security]) throws -> Credential {
        try tokenStorage.add(token: token,
                             metadata: Token.Metadata(token: token,
                                                      tags: tags),
                             security: security)
        return credentialDataSource.credential(for: token, coordinator: self)
    }
    
    @CredentialActor
    func with(id: String, prompt: String?, authenticationContext: (any TokenAuthenticationContext)?) throws -> Credential? {
        credentialDataSource.credential(for: try tokenStorage.get(token: id,
                                                                  prompt: prompt,
                                                                  authenticationContext: authenticationContext),
                                        coordinator: self)
    }
    
    @CredentialActor
    func find(where expression: @Sendable @escaping (Token.Metadata) -> Bool,
              prompt: String? = nil,
              authenticationContext: (any TokenAuthenticationContext)? = nil) throws -> [Credential]
    {
        try allIDs
            .map(tokenStorage.metadata(for:))
            .filter(expression)
            .compactMap({ metadata in
                try self.with(id: metadata.id, prompt: prompt, authenticationContext: authenticationContext)
            })
    }
    
    @CredentialActor
    func remove(credential: Credential) throws {
        credentialDataSource.remove(credential: credential)
        try tokenStorage.remove(id: credential.id)
    }
    
    /// Defer the execution of a block to the main thread.
    ///
    /// This triggers two nested Task operations, one within the ``CredentialActor``, and the second within the `MainActor`. The goal of this is to serialize external communications (e.g. notifications) to ensure any local tasks being performed by the credential coordinator can complete, and that consumers of the resulting call will receive them on the main thread.
    /// - Parameter notification: Notification to post
    private func deferToMainActor(_ block: @Sendable @escaping () -> Void) {
        Task { @CredentialActor in
            Task { @MainActor in
                block()
            }
        }
    }

    static func defaultCredential(tokenStorage: any TokenStorage,
                                  credentialDataSource: any CredentialDataSource,
                                  coordinator: any CredentialCoordinator) throws -> Credential?
    {
        if let defaultTokenId = tokenStorage.defaultTokenID {
            var context: (any TokenAuthenticationContext)?
            #if canImport(LocalAuthentication) && !os(tvOS)
            context = Credential.Security.standard.context
            #endif
            
            let token = try tokenStorage.get(token: defaultTokenId,
                                             prompt: nil,
                                             authenticationContext: context)
            return credentialDataSource.credential(for: token, coordinator: coordinator)
        }
        return nil
    }

    nonisolated func observe(oauth2 client: OAuth2Client) {
        client.add(delegate: self)
    }
}

extension CredentialCoordinatorImpl: OAuth2ClientDelegate {
    nonisolated func oauth(client: OAuth2Client, didRefresh token: Token, replacedWith newToken: Token?) {
        guard let newToken = newToken else {
            return
        }

        withIsolationSync {
            do {
                try await self.tokenStorage.replace(token: token.id,
                                                    with: newToken,
                                                    security: nil)
            } catch {
                print("Error happened refreshing: \(error)")
            }
        }
    }
}

extension CredentialCoordinatorImpl: TokenStorageDelegate {
    func token(storage: any TokenStorage, defaultChanged id: String?) {
        guard _default?.id != id else { return }

        if let id = id,
           let token = try? storage.get(token: id, prompt: nil, authenticationContext: nil)
        {
            _default = credentialDataSource.credential(for: token, coordinator: self)
        } else {
            _default = nil
        }

        let credential = _default
        Task { @MainActor in
            TaskData.notificationCenter.post(name: .defaultCredentialChanged,
                                             object: credential)
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

        deferToMainActor {
            TaskData.notificationCenter.post(name: .credentialCreated,
                                             object: credential)
        }
    }
    
    func credential(dataSource: any CredentialDataSource, removed credential: Credential) {
        credential.coordinator = nil

        deferToMainActor {
            TaskData.notificationCenter.post(name: .credentialRemoved,
                                             object: credential)
        }
    }
    
    func credential(dataSource: any CredentialDataSource, updated credential: Credential) {
    }
}
