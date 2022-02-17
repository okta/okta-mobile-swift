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

public protocol SessionLogoutFlowDelegate: LogoutFlowDelegate {
    func logout<Flow: SessionLogoutFlow>(flow: Flow, received error: OAuth2Error)
    
    func logout<Flow: SessionLogoutFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents)
    
    func logout<Flow: SessionLogoutFlow>(flow: Flow, shouldLogoutUsing url: URL)
}

public class SessionLogoutFlow: LogoutFlow {
    private(set) public var inProgress: Bool = false
    
    public struct Configuration: AuthenticationConfiguration {
        /// The redirect URI defined for your client.
        public let logoutRedirectUri: URL?
        
        public init(logoutRedirectUri: URL?) {
            self.logoutRedirectUri = logoutRedirectUri
        }
    }
    
    public struct Context: Codable, Equatable {
        public let idToken: String
        
        public let state: String
        
        internal(set) public var logoutURL: URL?
        
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
    
    private(set) public var context: Context? {
        didSet {
            guard let url = context?.logoutURL else {
                return
            }

            delegateCollection.invoke { $0.logout(flow: self, shouldLogoutUsing: url) }
        }
    }
    
    /// Initializer to construct an authentication flow from a pre-defined configuration and client.
    /// - Parameters:
    ///   - configuration: The configuration to use for this authentication flow.
    ///   - client: The `OAuth2Client` to use with this flow.
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }
    
    public func resume(idToken: String, completion: ((Result<URL, OAuth2Error>) -> Void)? = nil) throws {
        try resume(with: Context(idToken: idToken), completion: completion)
    }
    
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
    
    public func cancel() {
        
    }
    
    public func reset() {
        inProgress = false
        context = nil
    }
}

#if swift(>=5.5.1)
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
extension SessionLogoutFlow {
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
