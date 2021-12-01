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
    case error(_ error: Error)
}

public protocol OAuth2ClientDelegate: APIClientDelegate {
//    func oauth(client: Client<T>, customize url: inout URL, for endpoint: Client<T>.Endpoint)
}

public class OAuth2Client: APIClient {
    public let session: URLSession
    public let baseURL: URL
    public var additionalHttpHeaders: [String:String]? = nil
    
    convenience public init(domain: String, session: URLSession = URLSession.shared) throws {
        guard let url = URL(string: "https://\(domain)") else {
            throw OAuth2Error.invalidUrl
        }
        
        self.init(baseURL: url, session: session)
    }
    
    public init(baseURL: URL, session: URLSession = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
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

    func received(_ response: APIResponse<Token>) {
        // Do something with the token
        print(response.result)
    }
    
    func exchange(token request: TokenRequest, completion: @escaping (Result<APIResponse<Token>, APIClientError>) -> Void) {
        send(request, completion: completion)
    }

    // MARK: Private properties / methods
    private let delegates = DelegateCollection<OAuth2ClientDelegate>()
}

extension OAuth2Client: UsesDelegateCollection {
    public typealias Delegate = OAuth2ClientDelegate
    public func add(delegate: Delegate) { delegates += delegate }
    public func remove(delegate: Delegate) { delegates -= delegate }
    
    public var delegateCollection: DelegateCollection<OAuth2ClientDelegate> {
        delegates
    }
}

/*
public func authenticate(username: String,
                         password: String,
                         domain: String,
                         completion: @escaping(Result<Credential, OAuth2Error>) -> Void)
{
//    let flow = Authentication.ResourceOwnerFlow(username: username,
//                                                password: password,
//                                                domain: domain)
//    let client = Client(flow: flow)
}
    */

/*
extension Client {
    public func authenticate<Flow: AuthenticationFlow>(
        using flow: Flow,
        completion: @escaping (Result<Credential, OAuth2Error>) -> Void)
    {
        
    }
    
    func exchangeCode<Flow: AuthenticationFlow>(from flow: Flow,
                                                using redirectUri: URL,
                                                completion: @escaping(Result<Credential, OAuth2Error>) -> Void)
    {
        guard var urlComponents = URLComponents(url: flow.configuration.baseUrl, resolvingAgainstBaseURL: true) else {
            completion(.failure(.invalidUrl))
            return
        }
        
        var formParameters = [
            "client_id": flow.configuration.clientId,
            "scope": configuration.scopes,
            "code_challenge": codeChallenge,
            "code_challenge_method": "S256",
            "redirect_uri": configuration.redirectUri.absoluteString,
            "state": state
        ]

        do {
            formParameters = try queryParameters()
        } catch {
            completion(.failure(error as? OAuth2Error ?? .error(error)))
            return
        }

        urlComponents.path = "/v1/token"

        delegate?.authentication(flow: self, customizeUrl: &urlComponents)
        
        guard let authorizeUrl = urlComponents.url else {
            completion(.failure(.invalidUrl))
            return
        }
        
        var request = URLRequest(url: authorizeUrl,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 30)
        request.httpMethod = "POST"
        request.httpBody = URLRequest.oktaURLFormEncodedString(for: formParameters)?.data(using: .utf8)

//        let task = session.dataTask(with: request) { data, response, error in
//            <#code#>
//        }
//        task.resume()

    }
}

@available(iOS 15.0.0, tvOS 15.0.0, watchOS 8.0.0, macOS 12.0.0, *)
public func authenticate(username: String,
                         password: String,
                         domain: String) async throws  -> Credential
{
    try await withCheckedThrowingContinuation({ continuation in
        authenticate(username: username, password: password, domain: domain) { result in
            continuation.resume(with: result)
        }
    })
}

extension Client {
    public enum Endpoint {
        case authorize, requestToken
    }
}
*/
