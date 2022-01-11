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

public protocol OAuth2Configuration {}

public enum OAuth2Error: Error {
    case invalidUrl
    case cannotComposeUrl
    case cannotGeneratePKCE
    case missingRequiredDelegate
    case invalidRedirect(message: String)
    case invalidState(_ state: String?)
    case oauth2Error(code: String, description: String?)
    case network(error: APIClientError)
    case flowNotReady(message: String)
    case missingResultCode
    case noResultReturned
    case missingToken(type: Token.Kind)
    case error(_ error: Error)
}

public protocol OAuth2ClientDelegate: APIClientDelegate {
//    func oauth(client: Client<T>, customize url: inout URL, for endpoint: Client<T>.Endpoint)
}

/// An OAuth2 client, used to interact with a given authorization server.
///
/// This class serves two purposes:
/// 1. Expose high-level actions a client can perform against an OAuth2 service.
/// 2. Connect authentication flows to the OAuth2 servers they intend to authenticate against.
///
/// Authentication flows represent the variety of ways authentication can occur, and in many cases involves multiple discrete steps. These often require interaction with individual actions (such as fetching OpenID configuration, accessing JWKS keys, and exchanging tokens), so these are encapsulated within the OAuth2Client for code sharing and ease of use.
///
/// The OAuth2Client is itself an APIClient, defined from within the AuthFoundation framework, and provides extensibility hooks.
public class OAuth2Client: APIClient {
    /// The URLSession used by this client for network requests.
    public let session: URLSessionProtocol
    
    /// The base URL that identifies this OAuth2 org.
    public let baseURL: URL
    
    /// Additional HTTP headers to include in outgoing network requests.
    public var additionalHttpHeaders: [String:String]? = nil
    
    /// The OpenID configuration for this org.
    ///
    /// This value will be `nil` until the configuration has been retrieved through the ``openIdConfiguration(completion:)`` or ``openIdConfiguration()`` functions.
    private(set) public var openIdConfiguration: OpenIdConfiguration?
    
    /// Constructs an OAuth2Client for the given domain.
    /// - Parameters:
    ///   - domain: Okta domain to use for the base URL.
    ///   - session: Optional URLSession to use for network requests.
    convenience public init(domain: String, session: URLSessionProtocol? = nil) throws {
        guard let url = URL(string: "https://\(domain)") else {
            throw OAuth2Error.invalidUrl
        }
        
        self.init(baseURL: url, session: session)
    }
    
    /// Constructs an OAuth2Client for the given base URL.
    /// - Parameters:
    ///   - baseURL: Base URL representing the Okta domain to use.
    ///   - session: Optional URLSession to use for network requests.
    public init(baseURL: URL, session: URLSessionProtocol? = nil) {
        var baseURL = baseURL
        
        // Ensure the base URL includes the path to the OAuth2 API
        if !baseURL.path.contains("/oauth2/") {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
            components?.path = "/oauth2/default/"
            if let url = components?.url {
                baseURL = url
            }
        }
        
        self.baseURL = baseURL
        self.session = session ?? URLSession.shared
        
        NotificationCenter.default.post(name: .oauth2ClientCreated, object: self)
    }
    
    public func error(from data: Data) -> Error? {
        if let error = try? decode(OktaAPIError.self, from: data) {
            return error
        }
        
        if let error = try? decode(OAuth2ServerError.self, from: data) {
            return error
        }
        
        return nil
    }

    public func willSend(request: inout URLRequest) {
        delegateCollection.invoke { $0.api(client: self, willSend: &request) }
    }
    
    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) where T : Decodable {
        delegateCollection.invoke { $0.api(client: self, didSend: request, received: response) }
    }
    
    func received(_ response: APIResponse<Token>) {
        // Do something with the token
        print(response.result)
    }
    
    /// Retrieves the org's OpenID configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Parameter completion: Completion block invoked with the result.
    public func openIdConfiguration(completion: @escaping (Result<OpenIdConfiguration, OAuth2Error>) -> Void) {
        if let openIdConfiguration = openIdConfiguration {
            completion(.success(openIdConfiguration))
        } else {
            fetchOpenIdConfiguration { result in
                switch result {
                case .success(let response):
                    completion(.success(response.result))
                case .failure(let error):
                    completion(.failure(.network(error: error)))
                }
            }
        }
    }
    
    public func refresh(_ token: Token, completion: @escaping (Result<Token, OAuth2Error>) -> Void) {
        guard let refreshSettings = token.configuration.refreshSettings else {
            completion(.failure(.missingToken(type: .refreshToken)))
            return
        }
        
        refresh(Token.RefreshRequest(token: token, configuration: refreshSettings)) { result in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(.network(error: error)))
            }
        }
    }
    
    public func revoke(_ token: Token, type: Token.RevokeType, completion: @escaping (Result<Void, OAuth2Error>) -> Void) {
        let tokenType = type.tokenType
        guard let tokenString = token.token(of: tokenType) else {
            completion(.failure(.missingToken(type: tokenType)))
            return
        }
        
        let request = Token.RevokeRequest(token: tokenString, hint: tokenType)
        revoke(request) { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.network(error: error)))
            }
        }
    }
    
    public func introspect(token: Token, type: Token.Kind, completion: @escaping (Result<[String:Claim], OAuth2Error>) -> Void) {
        introspect(Token.IntrospectRequest(token: token, type: type)) { result in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(.network(error: error)))
            }
        }
    }
    
    public func userInfo(token: Token, completion: @escaping (Result<UserInfo, OAuth2Error>) -> Void) {
        userInfo(UserInfo.Request(token: token)) { result in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(.network(error: error)))
            }
        }
    }
    
    public func keys(clientId: String, completion: @escaping (Result<JWKS, OAuth2Error>) -> Void) {
        keys(KeysRequest(clientId: clientId)) { result in
            switch result {
            case .success(let response):
                completion(.success(response.result))
            case .failure(let error):
                completion(.failure(.network(error: error)))
            }
        }
    }
    
    // MARK: Private properties / methods
    private let delegates = DelegateCollection<OAuth2ClientDelegate>()
}

#if swift(>=5.5.1) && !os(Linux)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
extension OAuth2Client {
    /// Asynchronously retrieves the org's OpenID configuration.
    ///
    /// If this value has recently been retrieved, the cached result is returned.
    /// - Returns: The OpenID configuration for the org identified by the client's base URL.
    public func openIdConfiguration() async throws -> OpenIdConfiguration {
        try await withCheckedThrowingContinuation { continuation in
            openIdConfiguration() { result in
                continuation.resume(with: result)
            }
        }
    }
}
#endif

extension OAuth2Client: UsesDelegateCollection {
    public typealias Delegate = OAuth2ClientDelegate
    public func add(delegate: Delegate) { delegates += delegate }
    public func remove(delegate: Delegate) { delegates -= delegate }
    
    public var delegateCollection: DelegateCollection<OAuth2ClientDelegate> {
        delegates
    }
}

extension Notification.Name {
    public static let oauth2ClientCreated = Notification.Name("com.okta.oauth2client.created")
}
