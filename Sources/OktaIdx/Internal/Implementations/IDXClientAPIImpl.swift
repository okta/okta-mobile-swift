/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
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
public protocol IDXClientAPI: class {
    var context: IDXClient.Context { get }
    func resume(completion: IDXClient.ResponseResult?)
    func proceed(remediation option: IDXClient.Remediation,
                 completion: IDXClient.ResponseResult?)

    func redirectResult(for url: URL) -> IDXClient.RedirectResult

    func exchangeCode(redirect url: URL,
                      completion: IDXClient.TokenResult?)

    func exchangeCode(using remediation: IDXClient.Remediation,
                      completion: IDXClient.TokenResult?)
}

/// Internal protocol used to implement the IDXClientAPI protocol.
protocol IDXClientAPIImpl: class {
    /// The client version for this API implementation.
    static var version: IDXClient.Version { get }
    
    /// The client configuration used when constructing the API implementation.
    var configuration: IDXClient.Configuration { get }
    
    /// The upstream client to communicate critical events to
    var client: IDXClientAPI? { get set }
    
    func start(state: String?, completion: @escaping (IDXClient.Context?, Error?) -> Void)
    func resume(completion: @escaping (_ reponse: IDXClient.Response?, _ error: Error?) -> Void)
    func proceed(remediation option: IDXClient.Remediation,
                 completion: @escaping (_ response: IDXClient.Response?, _ error: Swift.Error?) -> Void)
    
    func redirectResult(for url: URL) -> IDXClient.RedirectResult
    
    func exchangeCode(redirect url: URL,
                      completion: @escaping (_ token: IDXClient.Token?, _ error: Swift.Error?) -> Void)
    
    func exchangeCode(using remediation: IDXClient.Remediation,
                      completion: @escaping (_ token: IDXClient.Token?, _ error: Swift.Error?) -> Void)

    func revoke(token: String,
                type: String,
                completion: @escaping(_ successful: Bool, _ error: Error?) -> Void)
    func refresh(token: IDXClient.Token,
                 completion: @escaping(_ token: IDXClient.Token?, _ error: Error?) -> Void)
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
              completion: @escaping (ResponseType?, Error?) -> Void)
}

protocol IDXResponseJSONPath {
    func matchesV1(jsonPath: String) -> Bool
}
