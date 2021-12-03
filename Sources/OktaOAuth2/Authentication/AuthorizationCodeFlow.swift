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
import AuthFoundation

public protocol AuthorizationCodeFlowDelegate: AuthenticationDelegate {
    func authenticationStarted<Flow: AuthorizationCodeFlow>(flow: Flow)
    func authenticationFinished<Flow: AuthorizationCodeFlow>(flow: Flow)
    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, customizeUrl urlComponents: inout URLComponents)
    func authentication<Flow: AuthorizationCodeFlow>(flow: Flow, shouldAuthenticateUsing url: URL)
}

public class AuthorizationCodeFlow: AuthenticationFlow {
    public struct Configuration: AuthenticationConfiguration {
        public let issuer: URL
        public let clientId: String
        public let clientSecret: String?
        public let scopes: String
        public let responseType: Authentication.ResponseType
        public let redirectUri: URL
        public let logoutRedirectUri: URL?
        public let additionalParameters: [String:String]?

        public let baseURL: URL
        
        public init(issuer: URL,
                    clientId: String,
                    clientSecret: String? = nil,
                    state: String? = nil,
                    scopes: String,
                    responseType: Authentication.ResponseType = .code,
                    redirectUri: URL,
                    logoutRedirectUri: URL? = nil,
                    additionalParameters: [String:String]? = nil)
        {
            self.issuer = issuer
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.scopes = scopes
            self.responseType = responseType
            self.redirectUri = redirectUri
            self.logoutRedirectUri = logoutRedirectUri
            self.additionalParameters = additionalParameters
            
            var urlComponents = URLComponents(url: issuer, resolvingAgainstBaseURL: false)
            urlComponents?.path = "/oauth2/v1/"
            baseURL = urlComponents?.url ?? issuer
        }
    }
    
    public struct Context {
        public let pkce: PKCE?
        public let state: String

        public init(state: String? = nil) {
            self.state = state ?? UUID().uuidString
            pkce = PKCE()
        }
    }
    
    public let client: OAuth2Client
    public let configuration: Configuration

    private(set) public var isAuthenticating: Bool = false {
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
    
    private(set) public var waitingForAuthorization: Bool = false
    private(set) public var authenticationURL: URL? {
        didSet {
            guard let url = authenticationURL else {
                return
            }

            delegateCollection.invoke { $0.authentication(flow: self, shouldAuthenticateUsing: url) }
        }
    }
    private(set) public var context: Context?
    
    public lazy var callbackScheme: String? = {
        configuration.redirectUri.scheme
    }()

    public convenience init(issuer: URL,
                            clientId: String,
                            scopes: String,
                            responseType: Authentication.ResponseType = .code,
                            redirectUri: URL)
    {
        self.init(.init(issuer: issuer,
                        clientId: clientId,
                        clientSecret: nil,
                        scopes: scopes,
                        responseType: responseType,
                        redirectUri: redirectUri),
                  client: OAuth2Client(baseURL: issuer))
    }
    
    public init(_ configuration: Configuration, client: OAuth2Client) {
        self.client = client
        self.configuration = configuration
        
        client.add(delegate: self)
    }
    
    public func resume(with context: Context?) throws {
        let context = context ?? Context()

        let url = try createAuthenticationURL(using: context)
        self.context = context
        
        isAuthenticating = true
        authenticationURL = url
    }
    
    public func resume(with url: URL) throws {
        let code = try authorizationCode(from: url)

        let request = TokenRequest(clientId: configuration.clientId,
                                   clientSecret: configuration.clientSecret,
                                   redirectUri: configuration.redirectUri.absoluteString,
                                   grantType: .authorizationCode,
                                   grantValue: code,
                                   pkce: context?.pkce)
        client.exchange(token: request) { result in
            switch result {
            case .success(let response):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: response.result) }
            case .failure(let error):
                self.delegateCollection.invoke { $0.authentication(flow: self, received: .network(error: error)) }
            }
            
            self.isAuthenticating = false
        }
    }
    
    public func cancel() {}
    
    public func reset() {
        context = nil
    }

    // MARK: Private properties / methods
    public let delegateCollection = DelegateCollection<AuthorizationCodeFlowDelegate>()
}

extension AuthorizationCodeFlow: UsesDelegateCollection {
    public typealias Delegate = AuthorizationCodeFlowDelegate
}

extension AuthorizationCodeFlow {
    func authorizationCode(from url: URL) throws -> String {
        guard let context = context else {
            throw OAuth2Error.flowNotReady(message: "No context has been initialized")
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw OAuth2Error.invalidRedirect(message: "Authentication session returned neither a URL or an error")
        }
        
        guard components.scheme?.lowercased() == callbackScheme?.lowercased() else {
            throw OAuth2Error.invalidRedirect(message: "Received an unexpected callback scheme \(String(describing: components.scheme))")
        }
        
        guard let query = components.queryItems?.reduce(into: [String:String](), { partialResult, queryItem in
            if let value = queryItem.value {
                partialResult[queryItem.name] = value
            }
        }) else {
            throw OAuth2Error.invalidRedirect(message: "No query arguments provided")
        }
        
        guard query["state"] == context.state else {
            throw OAuth2Error.invalidState(query["state"])
        }
        
        if let errorCode = query["error"] {
            let description = query["error_description"]?
                .removingPercentEncoding?
                .replacingOccurrences(of: "+", with: " ")
            throw OAuth2Error.oauth2Error(code: errorCode,
                                          description: description)
        }
        
        guard let code = query["code"] else {
            throw OAuth2Error.missingResultCode
        }
        
        return code
    }
}

extension AuthorizationCodeFlow: OAuth2ClientDelegate {
    
}
