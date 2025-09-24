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
import CommonSupport
import AuthFoundation

#if !COCOAPODS
import CommonSupport
#endif

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
/// You can create an instance of  ``SessionLogoutFlow`` with your logout settings, and supply that to the initializer, along with a reference to your OAuth2Client for performing key operations and requests. Alternatively, you can use any of the initializers to simplify the process.
///
/// As an example, we'll use Swift Concurrency, since these asynchronous methods can be used inline easily, though ``SessionLogoutFlow`` can just as easily be used with completion blocks or through the use of the ``SessionLogoutFlowDelegate``.
///
/// ```swift
/// let logoutFlow = SessionLogoutFlow(issuerURL: issuer,
///                                    clientId: "myclientid",
///                                    scope: "openid profile",
///                                    logoutRedirectUri: URL(string: "com.example.app:/logout")!)
///
/// // Create the logout URL. Open this in a browser.
/// let authorizeUrl = try await flow.start()
/// ```
public actor SessionLogoutFlow: LogoutFlow {
    /// The OAuth2Client this logout flow will use.
    nonisolated public let client: OAuth2Client

    /// Any additional query string parameters you would like to supply to the authorization server.
    nonisolated public let additionalParameters: [String: any APIRequestArgument]?

    /// Indicates if this flow is currently in progress.
    nonisolated public var inProgress: Bool {
        withIsolationSync { await self._inProgress } ?? false
    }

    /// The context that stores the ID token and state for the current log-out session.
    nonisolated public var context: Context? {
        withIsolationSync { await self._context }
    }

    /// Convenience initializer to construct a logout flow.
    /// - Parameters:
    ///   - issuerURL: The issuer URL.
    ///   - clientId: The client ID.
    ///   - scope: The client's scopes.
    ///   - logoutRedirectUri: The logout redirect URI.
    ///   - additionalParameters: Optional additional parameters you would like to supply to the authorization server
    public init(issuerURL: URL,
                clientId: String,
                scope: ClaimCollection<[String]>,
                logoutRedirectUri: URL? = nil,
                additionalParameters: [String: String]? = nil)
    {
        self.init(client: .init(issuerURL: issuerURL,
                                clientId: clientId,
                                scope: scope,
                                logoutRedirectUri: logoutRedirectUri),
                  additionalParameters: additionalParameters)
    }

    /// Initializer to construct a logout flow from a pre-defined client.
    /// - Parameters:
    ///   - client: The `OAuth2Client` to use with this flow.
    ///   - additionalParameters: Optional additional parameters you would like to supply to the authorization server
    public init(client: OAuth2Client,
                additionalParameters: [String: any APIRequestArgument]? = nil)
    {
        assert(SDKVersion.oauth2 != nil)

        self.client = client
        self.additionalParameters = additionalParameters

        client.add(delegate: self)
    }

    /// Initiates an logout flow, with a required ``Context-swift.struct`` object.
    ///
    /// This method is used to begin a logout session. The method will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: The context, providing information to help in signing out the user.
    /// - Returns: The URL a user should be presented with within a broser, to begin a logout flow.
    public func start(with context: Context = .init()) async throws -> URL
    {
        _context = context
        _inProgress = true

        return try await withExpression {
            let openIdConfiguration = try await client.openIdConfiguration()
            guard let endSessionEndpoint = openIdConfiguration.endSessionEndpoint
            else {
                throw OAuth2Error.missingOpenIdConfiguration(attribute: "end_session_endpoint")
            }

            let url = try self.createLogoutURL(from: endSessionEndpoint,
                                               context: context)
            var context = context
            context.logoutURL = url
            _context = context
            return url
        } success: { result in
            Task { @MainActor in
                delegateCollection.invoke { $0.logout(flow: self, shouldLogoutUsing: result) }
            }
        } failure: { error in
            Task { @MainActor in
                delegateCollection.invoke { $0.logout(flow: self, received: OAuth2Error(error)) }
            }
        } finally: {
            finished()
        }
    }

    /// Cancels a current session logout flow.
    public func cancel() {
    }

    /// Resets a current session logout flow.
    public func reset() {
        finished()
        _context = nil
    }

    func finished() {
        _inProgress = false
    }

    nonisolated public let delegateCollection = DelegateCollection<any SessionLogoutFlowDelegate>()

    // MARK: Private properties / methods
    private var _inProgress: Bool = false
    private var _context: Context? {
        didSet {
            guard let url = _context?.logoutURL else {
                return
            }

            Task { @MainActor in
                delegateCollection.invoke { $0.logout(flow: self, shouldLogoutUsing: url) }
            }
        }
    }
}

extension SessionLogoutFlow {
    /// Initiates an logout flow, with a required ``Context-swift.struct`` object.
    ///
    /// This method is used to begin a logout session. The method will invoke the appropriate delegate methods when a response is received.
    /// - Parameters:
    ///   - context: The context, providing information to help in signing out the user.
    ///   - completion: Completion block for receiving the URL a user should be presented with within a browser, to begin a logout flow.
    nonisolated public func start(with context: Context = .init(),
                                  completion: @escaping @Sendable (Result<URL, OAuth2Error>) -> Void)
    {
        Task {
            do {
                completion(.success(try await start(with: context)))
            } catch {
                completion(.failure(OAuth2Error(error)))
            }
        }
    }
}

extension SessionLogoutFlow: UsesDelegateCollection {
    public typealias Delegate = SessionLogoutFlowDelegate
}

extension SessionLogoutFlow: OAuth2ClientDelegate {
}

private extension SessionLogoutFlow {
    func createLogoutURL(from endSessionEndpoint: URL,
                         context: SessionLogoutFlow.Context) throws -> URL
    {
        guard var components = URLComponents(url: endSessionEndpoint, resolvingAgainstBaseURL: true)
        else {
            throw OAuth2Error.invalidUrl
        }

        var result = self.additionalParameters ?? [:]
        result.merge(context.additionalParameters)

        result["client_id"] = client.configuration.clientId
        result["state"] = context.state

        if let idToken = context.idToken {
            result["id_token_hint"] = idToken
        }
        
        if let logoutHint = context.logoutHint {
            result["logout_hint"] = logoutHint
        }
        
        if let logoutRedirectUri = client.configuration.logoutRedirectUri {
            result["post_logout_redirect_uri"] = logoutRedirectUri.absoluteString
        }
        
        // If requesting a login prompt, the post_logout_redirect_uri should be omitted.
        if let prompt = result["prompt"] as? String,
           ["login", "consent", "login consent", "consent login"].contains(prompt.lowercased())
        {
            result.removeValue(forKey: "post_logout_redirect_uri")
        }

        components.percentEncodedQuery = result
            .mapValues(\.stringValue)
            .percentQueryEncoded

        delegateCollection.invoke { $0.logout(flow: self, customizeUrl: &components) }
        
        guard let url = components.url else {
            throw OAuth2Error.cannotComposeUrl
        }

        return url
    }
}

extension OAuth2Client {
    /// Creates a new session logout flow for this redirect URI.
    /// - Parameter additionalParameters: Optional additional parameters you would like to supply to the authorization server
    /// - Returns: ``SessionLogoutFlow`` to log out of this client.
    public func sessionLogoutFlow(additionalParameters: [String: any APIRequestArgument]? = nil) -> SessionLogoutFlow
    {
        SessionLogoutFlow(client: self,
                          additionalParameters: additionalParameters)
    }
}
