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

import Foundation
import OktaOAuth2

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum WebAuthenticationError: Error {
    case defaultPropertyListNotFound
    case invalidPropertyList(url: URL)
    case cannotParsePropertyList(_ error: Error?)
    case missingConfigurationValues
    case noCompatibleAuthenticationProviders
    case cannotComposeAuthenticationURL
    case authenticationProviderError(_ error: Error)
    case invalidRedirectScheme(_ scheme: String?)
    case userCancelledLogin
    case oauth2(error: OAuth2Error)
    case generic(error: Error)
    case genericError(message: String)
}

public class WebAuthentication {
    #if os(macOS)
    public typealias WindowAnchor = NSWindow
    #else
    public typealias WindowAnchor = UIWindow
    #endif
    
    private(set) public static var shared: WebAuthentication?
    
    public let flow: AuthorizationCodeFlow
    public var canStart: Bool { provider?.canStart ?? false }
    public var ephemeralSession: Bool = false
    
    var provider: WebAuthenticationProvider?
    private var completionBlock: ((Result<Token, WebAuthenticationError>) -> Void)?

    #if swift(>=5.5.1) && !os(Linux)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    public static func signIn(from window: WindowAnchor?) async throws -> Token {
        let client = try shared ?? .init()
        return try await client.start(from: window)
    }
    #endif

    /// Starts sign-in using the configured client.
    /// - Parameter window: Window from which the sign in process will be started from.
    public func start(from window: WindowAnchor?, completion: @escaping (Result<Token, WebAuthenticationError>) -> Void) {
        if provider != nil {
            cancel()
        }
        
        let provider = WebAuthentication.createWebAuthenticationProvider(flow: flow,
                                                                         delegate: self)
        self.completionBlock = completion
        self.provider = provider

        provider?.start(from: window)
    }
    
    #if swift(>=5.5.1) && !os(Linux)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    @MainActor
    public func start(from window: WindowAnchor?) async throws -> Token {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.start(from: window) { continuation.resume(with: $0) }
            }
        }
    }
    #endif
    
    /// Cancels the authentication session.
    public func cancel() {
        flow.cancel()
        provider?.cancel()
    }
    
    #if os(iOS)
    /// Attempts to resume sign in when the app is launched from a redirect URI.
    ///
    /// This is a convenience method that can simplify apps that use a UISceneDelegate. Scene-based applications receive URLs when the `UIWindowSceneDelegate.scene(_:openURLContexts:)` method is called; the set of contexts can be supplied to this method, which will filter out only those URLs that match the URL scheme defined in the client configuration. If no matching URLs are found, the call is ignored.
    /// - Parameter URLContexts: Set of `UIOpenURLContext` objects from which to attempt to resume authentication.
    @available(iOS 13.0, *)
    public func resume(with URLContexts: Set<UIOpenURLContext>) throws {
        try URLContexts
            .filter { $0.url.scheme?.lowercased() == flow.callbackScheme?.lowercased() }
            .map(\.url)
            .forEach { try resume(with: $0) }
    }
    #endif
    
    /// Attempts to resume sign in when the app is launched from a redirect URI.
    ///
    /// This method is used when the sign in process continues outside of the application and its embedded authentication browser. When the application is opened using this redirect URI, this method can be used to resume the flow using that URL.
    ///
    /// If the URI does not match the configured URI scheme, this method will thrown an error.
    /// - Parameter url: URL from which to attempt to resume authentication.
    public func resume(with url: URL) throws {
        guard url.scheme?.lowercased() == flow.callbackScheme?.lowercased()
        else {
            throw WebAuthenticationError.invalidRedirectScheme(url.scheme)
        }
        
        try flow.resume(with: url)
        
        let provider = provider
        self.provider = nil
        provider?.cancel()
    }
    
    private func complete(with result: Result<Token, WebAuthenticationError>) {
        guard let completion = completionBlock else {
            return
        }

        completion(result)
        completionBlock = nil
        provider = nil
        flow.reset()
    }
    
    public convenience init() throws {
        guard let file = Bundle.main.url(forResource: "Okta", withExtension: "plist") else {
            throw WebAuthenticationError.defaultPropertyListNotFound
        }
        
        try self.init(plist: file)
    }
    
    public convenience init(plist fileURL: URL) throws {
        guard fileURL.isFileURL else {
            throw WebAuthenticationError.invalidPropertyList(url: fileURL)
        }
        
        let plistContent: Any
        do {
            let data = try Data(contentsOf: fileURL)
            plistContent = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw WebAuthenticationError.cannotParsePropertyList(error)
        }
        
        guard let dict = plistContent as? [String: String] else {
            throw WebAuthenticationError.cannotParsePropertyList(nil)
        }
        
        guard let clientId = dict["clientId"],
              !clientId.isEmpty,
              let issuer = dict["issuer"],
              let issuerUrl = URL(string: issuer),
              let scopes = dict["scopes"],
              !scopes.isEmpty,
              let redirectUriString = dict["redirectUri"],
              let redirectUri = URL(string: redirectUriString)
        else {
            throw WebAuthenticationError.missingConfigurationValues
        }
        
        let logoutRedirectUri: URL?
        if let logoutRedirectUriString = dict["logoutRedirectUri"] {
            logoutRedirectUri = URL(string: logoutRedirectUriString)
        } else {
            logoutRedirectUri = nil
        }
        
        let clientSecret = dict["clientSecret"]
        
        // Filter only additional parameters
        let additionalParameters = dict.filter {
            !["clientId", "clientSecret", "issuer", "scopes", "redirectUri", "logoutRedirectUri"].contains($0.key)
        }

        self.init(issuer: issuerUrl,
                  clientId: clientId,
                  clientSecret: clientSecret,
                  scopes: scopes,
                  redirectUri: redirectUri,
                  logoutRedirectUri: logoutRedirectUri,
                  additionalParameters: additionalParameters.isEmpty ? nil : additionalParameters)
    }
    
    public convenience init(issuer: URL,
                            clientId: String,
                            clientSecret: String? = nil,
                            scopes: String,
                            responseType: Authentication.ResponseType = .code,
                            redirectUri: URL,
                            logoutRedirectUri: URL? = nil,
                            additionalParameters: [String:String]? = nil)
    {
        self.init(configuration: .init(issuer: issuer,
                                       clientId: clientId,
                                       clientSecret: clientSecret,
                                       scopes: scopes,
                                       responseType: responseType,
                                       redirectUri: redirectUri,
                                       logoutRedirectUri: logoutRedirectUri,
                                       additionalParameters: additionalParameters))
    }

    public convenience init(configuration: AuthorizationCodeFlow.Configuration, session: URLSession = URLSession.shared) {
        self.init(flow: .init(configuration,
                              client: .init(baseURL: configuration.issuer,
                                            session: session)))
    }
    
    public init(flow: AuthorizationCodeFlow) {
        self.flow = flow
        WebAuthentication.shared = self
    }
}

extension WebAuthentication: WebAuthenticationProviderDelegate {
    func authentication(provider: WebAuthenticationProvider, received result: Token) {
        complete(with: .success(result))
    }
    
    func authentication(provider: WebAuthenticationProvider, received error: Error) {
        let webError: WebAuthenticationError
        if let error = error as? WebAuthenticationError {
            webError = error
        } else if let error = error as? OAuth2Error {
            webError = .oauth2(error: error)
        } else {
            webError = .generic(error: error)
        }
        complete(with: .failure(webError))
    }
}
