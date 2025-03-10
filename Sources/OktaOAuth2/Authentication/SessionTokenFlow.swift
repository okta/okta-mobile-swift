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
public class SessionTokenFlow: AuthenticationFlow {
    public typealias Context = AuthorizationCodeFlow.Context
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The context that stores the state for the current authentication session.
    public private(set) var context: Context?

    /// Any additional query string parameters you would like to supply to the authorization server for all requests from this flow.
    public let additionalParameters: [String: APIRequestArgument]?

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
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: ClaimCollection<[String]>,
                            redirectUri: URL,
                            additionalParameters: [String: APIRequestArgument]? = nil) throws
    {
        try self.init(client: OAuth2Client(issuerURL: issuerURL,
                                           clientId: clientId,
                                           scope: scope,
                                           redirectUri: redirectUri),
                      additionalParameters: additionalParameters)
    }

    @_documentation(visibility: private)
    @inlinable
    public convenience init(issuerURL: URL,
                            clientId: String,
                            scope: some WhitespaceSeparated,
                            redirectUri: URL,
                            additionalParameters: [String: APIRequestArgument]? = nil) throws
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
    public required init(client: OAuth2Client,
                         additionalParameters: [String: APIRequestArgument]? = nil) throws
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
    ///   - completion: Completion invoked when a response is received.
    public func start(with sessionToken: String,
                      context: Context = .init(),
                      completion: @escaping (Result<Token, OAuth2Error>) -> Void)
    {
        isAuthenticating = true

        self.context = context

        var parameters = additionalParameters ?? [:]
        parameters["sessionToken"] = sessionToken
        
        let flow: AuthorizationCodeFlow
        do {
            flow = try AuthorizationCodeFlow(client: client, additionalParameters: parameters)
        } catch {
            completion(.failure(OAuth2Error(error)))
            return
        }
        
        flow.start(with: context) { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                completion(.failure(error))
            case .success(let response):
                self.complete(using: flow, url: response) { result in
                    switch result {
                    case .failure(let error):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: error) }
                        completion(.failure(error))
                    case .success(let response):
                        self.delegateCollection.invoke { $0.authentication(flow: self, received: response) }
                        completion(.success(response))
                    }
                    self.finished()
                }
            }
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
    public let delegateCollection = DelegateCollection<Delegate>()
    static var urlExchangeClass: SessionTokenFlowURLExchange.Type = SessionTokenFlowExchange.self
    
    static func reset() {
        urlExchangeClass = SessionTokenFlowExchange.self
    }
    
    private func complete(using flow: AuthorizationCodeFlow, url: URL, completion: @escaping (Result<Token, OAuth2Error>) -> Void) {
        guard let scheme = client.configuration.redirectUri?.scheme else {
            completion(.failure(.invalidUrl))
            return
        }
        
        let follow = SessionTokenFlow.urlExchangeClass.init(scheme: scheme)
        follow.follow(url: url) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let url):
                do {
                    try flow.resume(with: url, completion: completion)
                } catch let error as OAuth2Error {
                    completion(.failure(error))
                } catch let error as APIClientError {
                    completion(.failure(.network(error: error)))
                } catch {
                    completion(.failure(.error(error)))
                }
            }
        }
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension SessionTokenFlow {
    /// Asynchronously authenticates with the given session token.
    public func start(with sessionToken: String,
                      context: Context = .init()) async throws -> Token
    {
        try await withCheckedThrowingContinuation { continuation in
            start(with: sessionToken, context: context) { result in
                continuation.resume(with: result)
            }
        }
    }
}

protocol SessionTokenFlowURLExchange {
    init(scheme: String)
    func follow(url: URL, completion: @escaping (Result<URL, OAuth2Error>) -> Void)
}

final class SessionTokenFlowExchange: NSObject, SessionTokenFlowURLExchange, URLSessionTaskDelegate {
    let scheme: String

    private var activeTask: URLSessionTask?
    private var completion: ((Result<URL, OAuth2Error>) -> Void)?
    private lazy var session: URLSession = {
        URLSession(configuration: .ephemeral,
                   delegate: self,
                   delegateQueue: nil)
    }()
    
    required init(scheme: String) {
        self.scheme = scheme
    }

    func follow(url: URL, completion: @escaping (Result<URL, OAuth2Error>) -> Void) {
        self.completion = completion

        activeTask = session.dataTask(with: URLRequest(url: url)) { [weak self] _, _, error in
            if let error = error {
                self?.finish(with: .error(error))
            } else {
                self?.finish(with: .invalidUrl)
            }
        }
        activeTask?.resume()
    }
    
    private func finish(with error: OAuth2Error) {
        completion?(.failure(error))
        completion = nil
        activeTask = nil
    }
    
    private func finish(with url: URL) {
        completion?(.success(url))
        completion = nil
        activeTask = nil
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void)
    {
        guard task == activeTask,
              let url = request.url,
              url.scheme == scheme
        else {
            completionHandler(request)
            return
        }
        
        completionHandler(nil)
        
        finish(with: url)
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
