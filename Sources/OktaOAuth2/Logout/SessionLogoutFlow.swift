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

/// The delegate of a ``SessionLogoutFlow`` may adopt some, or all, of the methods described here. These allow a developer to customize or interact with the logout flow during logout session.
///
/// This protocol extends the basic ``LogoutFlowDelegate`` which all logout flows support.
public protocol SessionLogoutFlowDelegate: LogoutFlowDelegate {
    /// Sent when the session logout flow receives an error.
    ///
    /// - Parameters:
    ///   - flow: The logout flow.
    ///   - error: The received error.
    func logout<Flow: SessionLogoutFlow>(flow: Flow, received error: OAuth2Error)
    
    /// Provides the opportunity to customize the logout URL.
    ///
    /// The logout URL is generated from a combination of configuration sources, as well as the end session endpoint's OpenID configuration. When specific values need to be added to the URL, such as custom query string or other URL parameters, this delegate method enables you to manipulate the URL before it is passed to a web browser.
    /// - Parameters:
    ///   - flow: The logout flow.
    ///   - urlComponents: A `URLComponents` instance that represents the logout URL, prior to conversion to a URL.
    func logout<Flow: SessionLogoutFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents)
    
    /// Called when the logout URL has been created, indicating the URL should be presented to the user.
    /// - Parameters:
    ///   - flow: The session logout flow.
    ///   - url: The logout URL to display in a browser to the user.
    func logout<Flow: SessionLogoutFlow>(flow: Flow, shouldLogoutUsing url: URL)
}

/// An logout flow class that implements the Session Logout Flow.
///
/// The Session Logout Flow permits a user to logout using a web browser redirect model, where an initial logout URL is loaded in a browser, they log out through some external service, after which their browser is redirected to a URL whose scheme matches the one defined in the client configuration.
///
/// You can create an instance of  ``SessionLogoutFlow`` with your logout settings, and supply that to the initializer, along with a reference to your OAuth2Client for performing key operations and requests. Alternatively, you can use any of the convenience initializers to simplify the process.
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``SessionLogoutFlow`` can just as easily be used with completion blocks or through the use of the ``SessionLogoutFlowDelegate``.
///
/// ```swift
/// let logoutFlow = SessionLogoutFlow(issuer: issuer,
///                                    logoutRedirectUri: URL(string: "com.example.app:/logout")!)
///
/// // Create the logout URL. Open this in a browser.
/// let authorizeUrl = try await flow.start()
/// ```
public class SessionLogoutFlow: LogoutFlow {
    /// A model representing the context and current state for a logout session.
    public struct Context: Codable, Equatable {
        /// The ID token string used for log-out.
        public let idToken: String
        
        /// The state string to use when creating an logout URL.
        public let state: String
        
        /// The current logout URL, or `nil` if one has not yet been generated.
        public internal(set) var logoutURL: URL?
        
        /// Initializer for creating a context.
        /// - Parameters:
        ///   - idToken: The ID token string used for log-out.
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        public init(idToken: String, state: String? = nil) {
            self.idToken = idToken
            self.state = state ?? UUID().uuidString
        }
    }
    
    /// The OAuth2Client this logout flow will use.
    public let client: OAuth2Client
    
    /// The logout redirect URI.
    public let logoutRedirectUri: URL
    
    /// Any additional query string parameters you would like to supply to the authorization server.
    public let additionalParameters: [String: String]?

    /// Indicates if this flow is currently in progress.
    public private(set) var inProgress: Bool = false
    
    /// The context that stores the ID token and state for the current log-out session.
    public private(set) var context: Context? {
        didSet {
            guard let url = context?.logoutURL else {
                return
            }

            delegateCollection.invoke { $0.logout(flow: self, shouldLogoutUsing: url) }
        }
    }
    
    /// Convenience initializer to construct a logout flow.
    /// - Parameters:
    ///   - issuer: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scopes: The client's scopes.
    ///   - logoutRedirectUri: The logout redirect URI.
    public convenience init?(issuer: URL,
                             clientId: String,
                             scopes: String,
                             logoutRedirectUri: URL?,
                             additionalParameters: [String: String]? = nil)
    {
        guard let logoutRedirectUri = logoutRedirectUri else {
            return nil
        }

        self.init(logoutRedirectUri: logoutRedirectUri,
                  additionalParameters: additionalParameters,
                  client: OAuth2Client(baseURL: issuer,
                                       clientId: clientId,
                                       scopes: scopes))
    }
    
    /// Initializer to construct a logout flow from a pre-defined client.
    /// - Parameters:
    ///   - logoutRedirectUri: The logout redirect URI.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(logoutRedirectUri: URL,
                additionalParameters: [String: String]? = nil,
                client: OAuth2Client)
    {
        // Ensure this SDK's static version is included in the user agent.
        SDKVersion.register(sdk: Version)
        
        self.client = client
        self.logoutRedirectUri = logoutRedirectUri
        self.additionalParameters = additionalParameters
        
        client.add(delegate: self)
    }

    /// Initiates a logout flow, with a required ID Token.
    ///
    /// This method is used to begin a logout session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - idToken: The ID token string.
    ///   - additionalParameters: Optional parameters to add to the authorization URL query string.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func start(idToken: String,
                      additionalParameters: [String: String]? = nil,
                      completion: @escaping (Result<URL, OAuth2Error>) -> Void) throws
    {
        try start(with: Context(idToken: idToken),
                  additionalParameters: additionalParameters,
                  completion: completion)
    }

    /// Initiates an logout flow, with a required ``Context-swift.struct`` object.
    ///
    /// This method is used to begin a logout session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Represents current state for a logout session.
    ///   - additionalParameters: Optional parameters to add to the authorization URL query string.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func start(with context: Context,
                      additionalParameters: [String: String]? = nil,
                      completion: @escaping (Result<URL, OAuth2Error>) -> Void) throws
    {
        guard !inProgress else {
            completion(.failure(.missingClientConfiguration))
            return
        }
        
        inProgress = true
        
        client.openIdConfiguration { result in
            defer { self.reset() }
            
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.logout(flow: self, received: error) }
                completion(.failure(error))
            case .success(let configuration):
                do {
                    guard let endSessionEndpoint = configuration.endSessionEndpoint else {
                        throw OAuth2Error.missingOpenIdConfiguration(attribute: "end_session_endpoint")
                    }
                    
                    let url = try self.createLogoutURL(from: endSessionEndpoint,
                                                       using: context,
                                                       additionalParameters: additionalParameters)
                    var context = context
                    context.logoutURL = url
                    self.context = context
                    
                    completion(.success(url))
                } catch {
                    let oauthError = error as? OAuth2Error ?? .error(error)
                    self.delegateCollection.invoke { $0.logout(flow: self, received: oauthError) }
                    completion(.failure(oauthError))
                }
            }
        }
    }
    
    /// Cancels a current session logout flow.
    public func cancel() {
        
    }
    
    /// Resets a current session logout flow.
    public func reset() {
        inProgress = false
        context = nil
    }

    public let delegateCollection = DelegateCollection<SessionLogoutFlowDelegate>()
}

#if swift(>=5.5.1)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
extension SessionLogoutFlow {
    /// Asynchronously initiates a logout flow, with a required ID Token.
    ///
    /// This method is used to begin a logout session. The method will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - idToken: The ID token string.
    ///   - additionalParameters: Optional parameters to add to the authorization URL query string.
    /// - Returns: The URL a user should be presented with within a broser, to befing a logout flow.
    public func start(idToken: String,
                      additionalParameters: [String: String]? = nil) async throws -> URL
    {
        try await start(with: .init(idToken: idToken),
                        additionalParameters: additionalParameters)
    }
    
    /// Initiates an logout flow, with a required ``Context-swift.struct`` object.
    ///
    /// This method is used to begin a logout session. The method will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Represents current state for a logout session.
    ///   - additionalParameters: Optional parameters to add to the authorization URL query string.
    /// - Returns: The URL a user should be presented with within a broser, to befing a logout flow.
    public func start(with context: Context,
                      additionalParameters: [String: String]? = nil) async throws -> URL
    {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try start(with: context, additionalParameters: additionalParameters) { result in
                    continuation.resume(with: result)
                }
            } catch let error as APIClientError {
                continuation.resume(with: .failure(error))
            } catch {
                continuation.resume(with: .failure(APIClientError.serverError(error)))
            }
        }
    }
}
#endif

extension SessionLogoutFlow: UsesDelegateCollection {
    public typealias Delegate = SessionLogoutFlowDelegate
}

extension SessionLogoutFlow: OAuth2ClientDelegate {
}

private extension SessionLogoutFlow {
    func logoutUrlComponents(from logoutUrl: URL,
                             using context: SessionLogoutFlow.Context,
                             additionalParameters: [String: String]?) throws -> URLComponents
    {
        guard var components = URLComponents(url: logoutUrl, resolvingAgainstBaseURL: true)
        else {
            throw OAuth2Error.invalidUrl
        }
        
        components.percentEncodedQuery = queryParameters(using: context, additionalParameters: additionalParameters).percentQueryEncoded

        return components
    }
    
    func queryParameters(using context: SessionLogoutFlow.Context,
                         additionalParameters: [String: String]?) -> [String: String] {
        var result = [String: String]()
        if let additional = self.additionalParameters {
            result.merge(additional, uniquingKeysWith: { $1 })
        }

        if let additional = additionalParameters {
            result.merge(additional, uniquingKeysWith: { $1 })
        }

        result["id_token_hint"] = context.idToken
        result["post_logout_redirect_uri"] = logoutRedirectUri.absoluteString
        result["state"] = context.state
        
        // If requesting a login prompt, the post_logout_redirect_uri should be omitted.
        if let prompt = additionalParameters?["prompt"]?.lowercased(),
           ["login", "consent", "login consent", "consent login"].contains(prompt)
        {
            result.removeValue(forKey: "post_logout_redirect_uri")
        }
        
        return result
    }

    func createLogoutURL(from url: URL,
                         using context: SessionLogoutFlow.Context,
                         additionalParameters: [String: String]?) throws -> URL
    {
        var components = try logoutUrlComponents(from: url,
                                                 using: context,
                                                 additionalParameters: additionalParameters)
        delegateCollection.invoke { $0.logout(flow: self, customizeUrl: &components) }
        
        guard let url = components.url else {
            throw OAuth2Error.cannotComposeUrl
        }

        return url
    }
}

extension OAuth2Client {
    /// Creates a new session logout flow for this redirect URI.
    /// - Parameter logoutRedirectUri: Logout redirect URI to use
    /// - Returns: ``SessionLogoutFlow`` to log out of this client.
    public func sessionLogoutFlow(logoutRedirectUri: URL) -> SessionLogoutFlow {
        SessionLogoutFlow(logoutRedirectUri: logoutRedirectUri, client: self)
    }
}
