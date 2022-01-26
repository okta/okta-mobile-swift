/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

/// Internal protocol that defines the interface for the public IDXClient
public protocol IDXClientAPI: AnyObject {
    var context: IDXClient.Context { get }
    func resume(completion: IDXClient.ResponseResult?)
    func proceed(remediation option: Remediation,
                 completion: IDXClient.ResponseResult?)

    func redirectResult(for url: URL) -> IDXClient.RedirectResult

    func exchangeCode(redirect url: URL,
                      completion: IDXClient.TokenResult?)

    func exchangeCode(using remediation: Remediation,
                      completion: IDXClient.TokenResult?)
}

/// Internal protocol used to implement the IDXClientAPI protocol.
protocol IDXClientAPIImpl: AnyObject {
    /// The client version for this API implementation.
    static var version: IDXClient.Version { get }
    
    /// The client configuration used when constructing the API implementation.
    var configuration: IDXClient.Configuration { get }
    
    /// The upstream client to communicate critical events to
    var client: IDXClientAPI? { get set }
    
    func start(options: [IDXClient.Option:String]?, completion: @escaping (Result<IDXClient.Context, IDXClientError>) -> Void)
    func resume(completion: @escaping (Result<Response, IDXClientError>) -> Void)
    func proceed(remediation option: Remediation,
                 completion: @escaping (Result<Response, IDXClientError>) -> Void)
    
    func redirectResult(for url: URL) -> IDXClient.RedirectResult
    
    func exchangeCode(redirect url: URL,
                      completion: @escaping (Result<Token, IDXClientError>) -> Void)
    
    func exchangeCode(using remediation: Remediation,
                      completion: @escaping (Result<Token, IDXClientError>) -> Void)

    func revoke(token: String,
                type: String,
                completion: @escaping(Result<Void, IDXClientError>) -> Void)
    func refresh(token: Token,
                 completion: @escaping(Result<Token, IDXClientError>) -> Void)
}

/// Protocol used to represent IDX API requests, and their expected response types.
protocol IDXClientAPIRequest {
    associatedtype ResponseType
    /// Produces a URLRequest suitable for performing the request.
    /// - Parameter configuration: Client configuration.
    func urlRequest(using configuration:IDXClient.Configuration) -> URLRequest?
    
    /// Sends the request to the given URL session, returning the response asynchronously to the supplied completion block.
    /// - Parameters:
    ///   - session: URL session to send the network request on.
    ///   - configuration: Client configuration.
    ///   - completion: Completion handler to receive the response.
    func send(to session: URLSessionProtocol,
              using configuration: IDXClient.Configuration,
              completion: @escaping (Result<ResponseType, IDXClientError>) -> Void)
}

protocol IDXResponseJSONPath {
    func matchesV1(jsonPath: String) -> Bool
}
