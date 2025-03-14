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
import AuthFoundation

#if os(Linux)
import FoundationNetworking
#endif

/// An authentication flow class that exchanges a Session Token for access tokens.
///
/// This flow is typically used in conjunction with the [classic Okta native authentication library](https://github.com/okta/okta-auth-swift). For native authentication using the Okta Identity Engine (OIE), please use the [Okta IDX library](https://github.com/okta/okta-idx-swift).
public actor SessionTokenFlow: AuthenticationFlow {
    public typealias Context = AuthorizationCodeFlow.Context
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The context that stores the state for the current authentication session.
    public private(set) var context: Context?

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    public let additionalParameters: [String: any APIRequestArgument]?

    /// Indicates whether or not this flow is currently in the process of authenticating a user.
    public private(set) var isAuthenticating: Bool = false {
        didSet {
            guard oldValue != isAuthenticating else {
                return
            }
            
            if isAuthenticating {
                delegateCollection.invoke { $0.authenticationStarted(flow: self) }
            } else {
                delegateCollection.invoke { $0.authenticationFinished(flow: self) }
            }
        }
    }
    
    /// Convenience initializer to construct an authentication flow from variables.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID
    ///   - scope: The scopes to request
    ///   - additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    @inlinable
    public init(issuerURL: URL,
                clientId: String,
                scope: ClaimCollection<[String]>,
                redirectUri: URL,
                additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        try self.init(client: OAuth2Client(issuerURL: issuerURL,
                                           clientId: clientId,
                                           scope: scope,
                                           redirectUri: redirectUri),
                      additionalParameters: additionalParameters)
    }

    @_documentation(visibility: private)
    @inlinable
    public init(issuerURL: URL,
                clientId: String,
                scope: some WhitespaceSeparated,
                redirectUri: URL,
                additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        try self.init(client: OAuth2Client(issuerURL: issuerURL,
                                           clientId: clientId,
                                           scope: scope,
                                           redirectUri: redirectUri),
                      additionalParameters: additionalParameters)
    }

    /// Initializer that uses the predefined OAuth2Client
    /// - Parameters:
    ///   - client: ``OAuth2Client`` client instance to authenticate with.
    ///   - additionalParameters: Optional query parameters to supply tot he authorization server for all requests from this flow.
    public init(client: OAuth2Client,
                additionalParameters: [String: any APIRequestArgument]? = nil) throws
    {
        guard client.configuration.redirectUri != nil else {
            throw OAuth2Error.missingRedirectUri
        }
        
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }
    
    /// Authenticates using the supplied session token.
    /// - Parameters:
    ///   - sessionToken: Session token to exchange.
    ///   - context: Optional context to provide when customizing the state parameter.
    /// - Returns: The token once the responce is received.
    public func start(with sessionToken: String,
                      context: Context = .init()) async throws -> Token
    {
        isAuthenticating = true
        self.context = context

        var parameters = additionalParameters ?? [:]
        parameters["sessionToken"] = sessionToken
        
        return try await withExpression {
            let flow = try AuthorizationCodeFlow(client: client, additionalParameters: parameters)
            let url = try await flow.start(with: context)
            return try await complete(using: flow, url: url)
        } success: { result in
            delegateCollection.invoke { $0.authentication(flow: self, received: result) }
        } failure: { error in
            delegateCollection.invoke { $0.authentication(flow: self, received: OAuth2Error(error)) }
        } finally: {
            finished()
        }
    }
    
    /// Resets the flow for later reuse.
    public func reset() {
        finished()
        context = nil
    }
    
    func finished() {
        isAuthenticating = false
    }

    // MARK: Private properties / methods
    private static let lock = Lock()
    nonisolated public let delegateCollection = DelegateCollection<any Delegate>()
    nonisolated(unsafe) private static var _urlExchangeClass: any SessionTokenFlowURLExchange.Type = SessionTokenFlowExchange.self
    static var urlExchangeClass: any SessionTokenFlowURLExchange.Type {
        get {
            lock.withLock { _urlExchangeClass }
        }
        set {
            lock.withLock { _urlExchangeClass = newValue }
        }
    }

    static func reset() {
        urlExchangeClass = SessionTokenFlowExchange.self
    }
    
    private func complete(using flow: AuthorizationCodeFlow, url: URL) async throws -> Token {
        guard let scheme = client.configuration.redirectUri?.scheme else {
            throw OAuth2Error.invalidUrl
        }
        
        let follow = SessionTokenFlow.urlExchangeClass.init(scheme: scheme)
        let url = try await follow.follow(url: url)
        return try await flow.resume(with: url)
    }
}

extension SessionTokenFlow {
    /// Authenticates using the supplied session token.
    /// - Parameters:
    ///   - sessionToken: Session token to exchange.
    ///   - context: Optional context to provide when customizing the state parameter.
    ///   - completion: Completion invoked when a response is received.
    nonisolated public func start(with sessionToken: String,
                                  context: Context = .init(),
                                  completion: @escaping @Sendable (Result<Token, OAuth2Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await start(with: sessionToken, context: context)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

protocol SessionTokenFlowURLExchange {
    init(scheme: String)
    func follow(url: URL) async throws -> URL
}

actor SessionTokenFlowExchange: NSObject, SessionTokenFlowURLExchange, URLSessionTaskDelegate {
    let scheme: String

    private let lock = Lock()
    private var continuation: (CheckedContinuation<URL, any Error>)?
    private lazy var session: any URLSessionProtocol = {
        URLSession(configuration: .ephemeral,
                   delegate: self,
                   delegateQueue: nil)
    }()
    
    init(scheme: String) {
        self.scheme = scheme
    }

    func follow(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            Task {
                do {
                    let request = URLRequest(url: url)
                    let (_, _) = try await session.data(for: request)
                    self.finish(with: OAuth2Error.invalidUrl)
                } catch {
                    self.finish(with: error)
                }
            }
        }
    }
    
    private func finish(with error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
    
    private func finish(with url: URL) {
        continuation?.resume(returning: url)
        continuation = nil
    }
    
    nonisolated
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void)
    {
        guard let url = request.url,
              url.scheme == scheme
        else {
            completionHandler(request)
            return
        }
        
        completionHandler(nil)

        Task {
            await finish(with: url)
        }
    }
}

extension SessionTokenFlow: UsesDelegateCollection {
    public typealias Delegate = AuthenticationDelegate
}

extension SessionTokenFlow: OAuth2ClientDelegate {
    
}

extension OAuth2Client {
    /// Creates a new Session Token flow configured to use this OAuth2Client.
    /// - Parameters:
    ///   - redirectUri: Redirect URI
    ///   - additionalParameters: Additional parameters to pass to the flow
    /// - Returns: Initialized authorization flow.
    public func sessionTokenFlow(additionalParameters: [String: String]? = nil) throws -> SessionTokenFlow
    {
        try SessionTokenFlow(client: self,
                             additionalParameters: additionalParameters)
    }
}
