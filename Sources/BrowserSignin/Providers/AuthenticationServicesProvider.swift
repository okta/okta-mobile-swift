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
import CommonSupport
import OAuth2Auth

#if canImport(AuthenticationServices)
import AuthenticationServices

@available(iOS 12.0, macCatalyst 13.0, macOS 10.15, tvOS 16.0, visionOS 1.0, watchOS 6.2, *)
protocol AuthenticationServicesProviderSession: NSObjectProtocol, Sendable {
    init(url URL: URL, callbackURLScheme: String?, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler)
    
    @available(iOS 17.4, macOS 14.4, watchOS 10.4, tvOS 17.4, visionOS 1.1, *)
    init(url URL: URL, callback: ASWebAuthenticationSession.Callback, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler)

    @available(iOS 13.4, macCatalyst 13.4, macOS 10.15.4, watchOS 6.2, visionOS 1.0, tvOS 16.0, *)
    var canStart: Bool { get }

    @available(iOS 13.0, macCatalyst 13.0, macOS 10.15, watchOS 6.2, visionOS 1.0, tvOS 16.0, *)
    func start() -> Bool

    #if os(iOS) || os(macOS) || os(visionOS) || os(watchOS) || targetEnvironment(macCatalyst)
    #if !os(watchOS)
    @available(iOS 13.0, macCatalyst 13.0, macOS 10.15, visionOS 1.0, *)
    var presentationContextProvider: (any ASWebAuthenticationPresentationContextProviding)? { get set }
    #endif

    @available(iOS 13.0, macCatalyst 13.0, macOS 10.15, watchOS 6.2, visionOS 1.0, *)
    var prefersEphemeralWebBrowserSession: Bool { get set }

    func cancel()
    #endif
}

#if swift(<6.0)
@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
extension ASWebAuthenticationSession: @unchecked Sendable, AuthenticationServicesProviderSession {}
#else
@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
extension ASWebAuthenticationSession: @retroactive @unchecked Sendable, AuthenticationServicesProviderSession {}
#endif

@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
final class AuthenticationServicesProvider: NSObject, BrowserSignin.Provider {
    private(set) var authenticationSession: (any AuthenticationServicesProviderSession)? {
        get {
            lock.withLock { _authenticationSession }
        }
        set {
            lock.withLock { _authenticationSession = newValue }
        }
    }

    init(from window: BrowserSignin.WindowAnchor?, usesEphemeralSession: Bool = false) throws {
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
        self.anchor = window
        #endif
        self.usesEphemeralSession = usesEphemeralSession
        
        super.init()
    }
    
    func createSession(authorizeUrl url: URL, callbackURL: URL, completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler) -> (any AuthenticationServicesProviderSession) {
        if #available(iOS 17.4, macOS 14.4, watchOS 10.4, tvOS 17.4, visionOS 1.1, *) {
            if let scheme = callbackURL.scheme {
                let callback: ASWebAuthenticationSession.Callback?
                if scheme == "https",
                   let host = callbackURL.host
                {
                    callback = .https(host: host, path: callbackURL.path)
                } else {
                    callback = .customScheme(scheme)
                }
                
                if let callback {
                    return Self.authenticationSessionClass.init(
                        url: url,
                        callback: callback,
                        completionHandler: completionHandler)
                }
            }
        }
        
        return Self.authenticationSessionClass.init(
            url: url,
            callbackURLScheme: callbackURL.scheme,
            completionHandler: completionHandler)
    }
    
    @MainActor
    func open(authorizeUrl: URL, redirectUri: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = createSession(authorizeUrl: authorizeUrl, callbackURL: redirectUri) { url, error in
                continuation.resume(with: self.process(redirectUri: redirectUri,
                                                       url: url,
                                                       error: error))
            }
            
            #if !os(watchOS) && !os(tvOS)
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = usesEphemeralSession
            #endif

            self.authenticationSession = session
            
            Task { @MainActor in
                if #available(iOS 13.4, macCatalyst 13.4, macOS 10.15.4, *) {
                    guard session.canStart else {
                        continuation.resume(throwing: BrowserSigninError.cannotStartBrowserSession)
                        return
                    }
                }
                
                _ = session.start()
            }
        }
    }
    
    func cancel() {
        #if os(iOS) || os(macOS) || os(visionOS) || targetEnvironment(macCatalyst)
        authenticationSession?.cancel()
        #endif
        authenticationSession = nil
    }
    
    func process(redirectUri: URL, url: URL?, error: (any Error)?) -> Result<URL, any Error> {
        defer { authenticationSession = nil }
        
        if let error = error as? OAuth2ServerError {
            return .failure(error)
        } else if let error = error {
            return .failure(BrowserSigninError(error))
        }
        
        guard let url = url else {
            return .failure(BrowserSigninError.noAuthenticatorProviderResonse)
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

    #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
    private let anchor: ASPresentationAnchor?
    #endif

    private let usesEphemeralSession: Bool

    nonisolated(unsafe) private static var _authenticationSessionClass: any AuthenticationServicesProviderSession.Type = ASWebAuthenticationSession.self
    nonisolated(unsafe) private var _authenticationSession: (any AuthenticationServicesProviderSession)?
}

// Work around a bug in Swift 5.10 that ignores `nonisolated(unsafe)` on mutable stored properties.
#if swift(<6.0)
@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
extension AuthenticationServicesProvider: @unchecked Sendable {}
#else
@available(iOS 13.0, macOS 10.15, tvOS 16.0, watchOS 7.0, visionOS 1.0, macCatalyst 13.0, *)
extension AuthenticationServicesProvider: Sendable {}
#endif

#if os(iOS) || os(macOS) || os(visionOS) || targetEnvironment(macCatalyst)
@available(iOS 13.0, macOS 10.15, visionOS 1.0, macCatalyst 13.0, *)
extension AuthenticationServicesProvider: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let anchor = anchor {
            return anchor
        }
        
        return MainActor.assumeIsolated {
            #if os(macOS)
            return NSWindow()
            #else
            return UIWindow()
            #endif
        }
    }
}
#endif
#endif
