//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import AuthFoundation
import OktaOAuth2

#if canImport(AuthenticationServices)
import AuthenticationServices

@available(iOS 12.0, macCatalyst 13.0, macOS 10.15, watchOS 6.2, tvOS 16.0, *)
protocol AuthenticationServicesProviderSession: NSObjectProtocol, Sendable {
    init(url URL: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler)

    @available(iOS 13.0, macOS 10.15, *)
    var presentationContextProvider: (any ASWebAuthenticationPresentationContextProviding)? { get set }

    @available(iOS 13.0, macOS 10.15, watchOS 6.2, *)
    var prefersEphemeralWebBrowserSession: Bool { get set }

    @available(iOS 13.4, macCatalyst 13.4, macOS 10.15.4, watchOS 6.2, *)
    var canStart: Bool { get }

    func start() -> Bool

    func cancel()
}

extension ASWebAuthenticationSession: @retroactive @unchecked Sendable, AuthenticationServicesProviderSession {}

protocol WebAuthenticationProviderFactory {
    static func createWebAuthenticationProvider(for webAuth: WebAuthentication,
                                                from window: WebAuthentication.WindowAnchor?,
                                                usesEphemeralSession: Bool) async throws -> (any WebAuthenticationProvider)?
}

final class AuthenticationServicesProvider: NSObject, WebAuthenticationProvider {
    private(set) var authenticationSession: (any AuthenticationServicesProviderSession)? {
        get {
            lock.withLock { _authenticationSession }
        }
        set {
            lock.withLock { _authenticationSession = newValue }
        }
    }

    init(from window: WebAuthentication.WindowAnchor?, usesEphemeralSession: Bool = false) throws {
        self.anchor = window
        self.usesEphemeralSession = usesEphemeralSession
        
        super.init()
    }

    @MainActor
    func open(authorizeUrl: URL, redirectUri: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = Self.authenticationSessionClass.init(
                url: authorizeUrl,
                callbackURLScheme: redirectUri.scheme,
                completionHandler: { url, error in
                    continuation.resume(with: self.process(redirectUri: redirectUri,
                                                           url: url,
                                                           error: error))
                })
            
            if #available(iOS 13.0, macCatalyst 13.0, *) {
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = usesEphemeralSession
            }
            
            self.authenticationSession = session
            
            Task { @MainActor in
                if #available(iOS 13.4, macCatalyst 13.4, macOS 10.15.4, watchOS 6.2, *) {
                    guard session.canStart else {
                        continuation.resume(throwing: WebAuthenticationError.cannotStartBrowserSession)
                        return
                    }
                }
                
                _ = session.start()
            }
        }
    }
    
    func cancel() {
        authenticationSession?.cancel()
        authenticationSession = nil
    }
    
    func process(redirectUri: URL, url: URL?, error: (any Error)?) -> Result<URL, any Error> {
        defer { authenticationSession = nil }
        
        if let error = error {
            if let url = url,
               let serverError = try? url.oauth2ServerError(redirectUri: redirectUri)
            {
                return .failure(serverError)
            } else {
                return .failure(WebAuthenticationError(error))
            }
        }
        
        guard let url = url else {
            return .failure(WebAuthenticationError.noAuthenticatorProviderResonse)
        }
        
        return .success(url)
    }

    // MARK: Internal test properties / methods

    static var authenticationSessionClass: any AuthenticationServicesProviderSession.Type {
        get {
            lock.withLock { _authenticationSessionClass }
        }
        set {
            lock.withLock { _authenticationSessionClass = newValue }
        }
    }

    static func resetToDefault() {
        lock.withLock {
            _authenticationSessionClass = ASWebAuthenticationSession.self
        }
    }

    // MARK: Private properties / methods
    private static let lock = Lock()
    private let lock = Lock()
    private let anchor: ASPresentationAnchor?
    private let usesEphemeralSession: Bool

    nonisolated(unsafe) private static var _authenticationSessionClass: any AuthenticationServicesProviderSession.Type = ASWebAuthenticationSession.self
    nonisolated(unsafe) private var _authenticationSession: (any AuthenticationServicesProviderSession)?
}

extension AuthenticationServicesProvider: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let anchor = anchor {
            return anchor
        }
        
        #if os(macOS)
        return NSWindow()
        #else
        return UIWindow()
        #endif
    }
}
#endif
