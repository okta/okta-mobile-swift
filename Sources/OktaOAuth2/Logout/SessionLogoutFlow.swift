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
    
    func logout<Flow: SessionLogoutFlow>(flow: Flow, shouldLogoutUsing url: URL)
}

/// An logout flow class that implements the Session Logout Flow.
///
/// The Session Logout Flow permits a user to authenticate using a web browser redirect model, where an initial authentication URL is loaded in a browser, they log out through some external service, after which their browser is redirected to a URL whose scheme matches the one defined in the client configuration.
///
/// You can create an instance of  ``SessionLogoutFlow/Configuration-swift.struct`` to define your logout settings, and supply that to the initializer, along with a reference to your OAuth2Client for performing key operations and requests. Alternatively, you can use any of the convenience initializers to simplify the process.
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``SessionLogoutFlow`` can just as easily be used with completion blocks or through the use of the ``SessionLogoutFlowDelegate``.
///
/// ```swift
/// let flow = AuthorizationCodeFlow(
///     issuer: URL(string: "https://example.okta.com")!,
///     clientId: "abc123client",
///     scopes: "openid offline_access email profile",
///     redirectUri: URL(string: "com.example.app:/callback"))
///
/// // Create the authorization URL. Open this in a browser.
/// let authorizeUrl = try await flow.resume()
///
/// // Once the browser redirects to the callback scheme
/// // from the redirect URI, use that to resume the flow.
/// let redirectUri: URL
/// let token = try await flow.resume(with: redirectUri)
/// ```
public class SessionLogoutFlow: LogoutFlow {
    /// Indicates if this flow is currently in progress.
    private(set) public var inProgress: Bool = false
    
    /// Configuration settings that define the OAuth2 client to be signed-out against.
    public struct Configuration: LogoutConfiguration {
        /// The logout redirect URI.
        public let logoutRedirectUri: URL?
        
        /// Convenience initializer for constructing an session logout flow configuration using the supplied values.
        /// - Parameter logoutRedirectUri: The logout redirect URI.
        public init(logoutRedirectUri: URL?) {
            self.logoutRedirectUri = logoutRedirectUri
        }
    }

    /// A model representing the context and current state for a logout session.
    public struct Context: Codable, Equatable {
        /// The ID token string used for log-out.
        public let idToken: String
        
        /// The state string to use when creating an logout URL.
        public let state: String
        
        /// The current logout URL, or `nil` if one has not yet been generated.
        internal(set) public var logoutURL: URL?
        
        /// Initializer for creating a context.
        /// - Parameters:
        ///   - idToken: The ID token string used for log-out.
        ///   - state: State string to use, or `nil` to accept an automatically generated default.
        public init(idToken: String, state: String? = nil) {
            self.idToken = idToken
            self.state = state ?? UUID().uuidString
        }
    }
    
    /// The OAuth2Client this authentication flow will use.
    public let client: OAuth2Client
    
    /// The configuration used when constructing this authentication flow.
    public let configuration: Configuration
    
    public let delegateCollection = DelegateCollection<SessionLogoutFlowDelegate>()
    
    /// The context that stores the ID token and state for the current log-out session.
    private(set) public var context: Context? {
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
    ///   - logoutRedirectUri: The logout redirect URI, if applicable.
    public convenience init(issuer: URL, logoutRedirectUri: URL?) {
        self.init(Configuration(logoutRedirectUri: logoutRedirectUri),
                  client: .init(baseURL: issuer))
    }
    
    /// Initializer to construct a logout flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }

    /// Initiates a logout flow, with a required ID Token.
    ///
    /// This method is used to begin a logout session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - idToken: The ID token string.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func resume(idToken: String, completion: ((Result<URL, OAuth2Error>) -> Void)? = nil) throws {
        try resume(with: Context(idToken: idToken), completion: completion)
    }

    /// Initiates an logout flow, with a required ``Context-swift.struct`` object.
    ///
    /// This method is used to begin a logout session. It is asynchronous, and will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Represents current state for a logout session.
    ///   - completion: Optional completion block for receiving the response. If `nil`, you may rely upon the appropriate delegate API methods.
    public func resume(with context: Context, completion: ((Result<URL, OAuth2Error>) -> Void)? = nil) throws {
        guard !inProgress else {
            completion?(.failure(.missingClientConfiguration))
            return
        }
        
        inProgress = true
        
        client.openIdConfiguration { result in
            switch result {
            case .failure(let error):
                self.delegateCollection.invoke { $0.logout(flow: self, received: error) }
                completion?(.failure(error))
            case .success(let configuration):
                do {
                    let url = try self.createLogoutURL(from: configuration.endSessionEndpoint,
                                                       using: context)
                    var context = context
                    context.logoutURL = url
                    self.context = context
                    
                    completion?(.success(url))
                } catch {
                    let oauthError = error as? OAuth2Error ?? .error(error)
                    self.delegateCollection.invoke { $0.logout(flow: self, received: oauthError) }
                    completion?(.failure(oauthError))
                }
            }
            
            self.inProgress = false
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
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension SessionLogoutFlow {
    /// Asynchronously initiates a logout flow, with a required ID Token.
    ///
    /// This method is used to begin a logout session. The method will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - idToken: The ID token string.
    /// - Returns: The URL a user should be presented with within a broser, to befing a logout flow.
    public func resume(idToken: String) async throws -> URL {
        try await resume(with: .init(idToken: idToken))
    }
    
    /// Initiates an logout flow, with a required ``Context-swift.struct`` object.
    ///
    /// This method is used to begin a logout session. The method will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: Represents current state for a logout session.
    /// - Returns: The URL a user should be presented with within a broser, to befing a logout flow.
    public func resume(with context: Context) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try resume(with: context) { result in
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

private extension SessionLogoutFlow.Configuration {
    func authenticationUrlComponents(from authenticationUrl: URL, using context: SessionLogoutFlow.Context) throws -> URLComponents {
        guard var components = URLComponents(url: authenticationUrl, resolvingAgainstBaseURL: true)
        else {
            throw OAuth2Error.invalidUrl
        }
        
        components.queryItems = queryParameters(using: context).map { (key, value) in
            URLQueryItem(name: key, value: value)
        }.sorted(by: { lhs, rhs in
            lhs.name < rhs.name
        })

        return components
    }
    
    func queryParameters(using context: SessionLogoutFlow.Context) -> [String: String] {
        [
            "id_token_hint": context.idToken,
            "post_logout_redirect_uri": logoutRedirectUri?.absoluteString,
            "state": context.state
        ].compactMapValues { $0 }
    }
}

private extension SessionLogoutFlow {
    func createLogoutURL(from url: URL, using context: SessionLogoutFlow.Context) throws -> URL {
        var components = try configuration.authenticationUrlComponents(from: url, using: context)
        delegateCollection.invoke { $0.logout(flow: self, customizeUrl: &components) }
        
        guard let url = components.url else {
            throw OAuth2Error.cannotComposeUrl
        }

        return url
    }
}
