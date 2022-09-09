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

#if os(Linux)
import FoundationNetworking
#endif

public protocol APIClientConfiguration: AnyObject {
    var baseURL: URL { get }
}

/// Protocol defining the interfaces and capabilities that API clients can conform to.
///
/// This provides a common pattern for network operations to be performed, and to centralize boilerplate handling of URL requests, provide customization extensions, and normalize response processing and argument handling.
public protocol APIClient {
    /// The base URL requests are performed against.
    ///
    /// This is used when request types may define their path as relative, and can inherit the URL they should be sent to through the client.
    var baseURL: URL { get }
    
    /// The URLSession requests are sent through.
    var session: URLSessionProtocol { get }
    
    /// Any additional headers that should be added to all requests sent through this client.
    var additionalHttpHeaders: [String: String]? { get }
    
    /// The name of the HTTP response header where unique request IDs can be found.
    var requestIdHeader: String? { get }
    
    /// The User-Agent string to be sent along with all outgoing requests.
    var userAgent: String { get }
    
    /// Decodes HTTP response data into an expected type.
    ///
    /// The userInfo property may be included, which can include contextual information that can help decoders formulate objects.
    /// - Returns: Decoded object.
    func decode<T: Decodable>(_ type: T.Type, from data: Data, userInfo: [CodingUserInfoKey: Any]?) throws -> T
    
    /// Parses HTTP response body data when a request fails.
    /// - Returns: Error instance, if any, described within the data.
    func error(from data: Data) -> Error?
    
    /// Invoked immediately prior to a URLRequest being converted to a DataTask.
    func willSend(request: inout URLRequest)
    
    /// Invoked when a request fails.
    func didSend(request: URLRequest, received error: APIClientError)
    
    /// Invoked when a request returns a successful response.
    func didSend<T>(request: URLRequest, received response: APIResponse<T>)
    
    /// Send the given URLRequest.
    func send<T: Decodable>(_ request: URLRequest, parsing context: APIParsingContext?, completion: @escaping (Result<APIResponse<T>, APIClientError>) -> Void)
    
    /// Provides the APIRetry configurations from the delegate in responds to a retry request.
    func shouldRetry(request: URLRequest, rateLimit: ApiRateLimit) -> APIRetry
}

/// Protocol that delegates of APIClient instances can conform to.
public protocol APIClientDelegate: AnyObject {
    /// Invoked immediately prior to a URLRequest being converted to a DataTask.
    func api(client: APIClient, willSend request: inout URLRequest)
    
    /// Invoked when a request fails.
    func api(client: APIClient, didSend request: URLRequest, received error: APIClientError)
    
    /// Invoked when a request returns a successful response.
    func api<T>(client: APIClient, didSend request: URLRequest, received response: APIResponse<T>)
    
    /// Provides the APIRetry configurations from the delegate in responds to a retry request.
    func api(client: APIClient, shouldRetry request: URLRequest) -> APIRetry
}

extension APIClientDelegate {
    public func api(client: APIClient, willSend request: inout URLRequest) {}
    public func api(client: APIClient, didSend request: URLRequest, received error: APIClientError) {}
    public func api<T>(client: APIClient, didSend request: URLRequest, received response: APIResponse<T>) {}
    public func api(client: APIClient, shouldRetry request: URLRequest) -> APIRetry {
        return .default
    }
}

/// List of retry options
public enum APIRetry {
    case doNotRetry
    case retry(maximumRetryCount: Int)
    
    public static let `default` = APIRetry.retry(maximumRetryCount: 3)
    
    struct State {
        let type: APIRetry
        let requestId: String
        let originalRequest: URLRequest
        let retryCount: Int
        
        func nextState() -> State {
            .init(type: type,
                  requestId: requestId,
                  originalRequest: originalRequest,
                  retryCount: retryCount + 1)
        }
    }
}

extension APIClient {
    public var additionalHttpHeaders: [String: String]? { nil }
    public var requestIdHeader: String? { "x-okta-request-id" }
    public var userAgent: String { SDKVersion.userAgent }
    
    public func error(from data: Data) -> Error? {
        defaultJSONDecoder.userInfo = [:]
        return try? defaultJSONDecoder.decode(OktaAPIError.self, from: data)
    }
    
    public func willSend(request: inout URLRequest) {}
    
    public func didSend(request: URLRequest, received error: APIClientError) {}
    
    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) {}
    
    public func send<T>(_ request: URLRequest, parsing context: APIParsingContext? = nil, completion: @escaping (Result<APIResponse<T>, APIClientError>) -> Void) {
        send(request, parsing: context, state: nil, completion: completion)
    }
    
    public func shouldRetry(request: URLRequest, rateLimit: ApiRateLimit) -> APIRetry { .default }
    
    private func send<T>(_ request: URLRequest,
                         parsing context: APIParsingContext? = nil,
                         state: APIRetry.State?,
                         completion: @escaping (Result<APIResponse<T>, APIClientError>) -> Void) {
        var urlRequest = request
        willSend(request: &urlRequest)
        session.dataTaskWithRequest(urlRequest) { data, response, httpError in
            guard let data = data,
                  let response = response
            else {
                let apiError: APIClientError
                if let error = httpError {
                    apiError = .serverError(error)
                } else {
                    apiError = .missingResponse
                }
                
                completion(.failure(apiError))
                return
            }
            
            do {
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIClientError.invalidResponse
                }
                
                let rateInfo = ApiRateLimit(with: httpResponse.allHeaderFields)
                switch httpResponse.statusCode {
                case 200..<300:
                    let response: APIResponse<T> = try self.validate(data: data,
                                                                     response: httpResponse,
                                                                     rateInfo: rateInfo,
                                                                     parsing: context)
                    self.didSend(request: request, received: response)
                    completion(.success(response))
                case 429:
                    guard let rateInfo = rateInfo else {
                        fallthrough
                    }
                    let retry = state?.type ?? self.shouldRetry(request: request, rateLimit: rateInfo)
                    switch retry {
                    case .doNotRetry: break
                    case .retry(let maximumRetryCount):
                        let retryState: APIRetry.State
                        if let state = state {
                            retryState = state.nextState()
                        } else {
                            guard let requestIdHeader = requestIdHeader,
                                  let requestId = httpResponse.allHeaderFields[requestIdHeader] as? String
                            else {
                                throw APIClientError.noRequestId
                            }
                            retryState = APIRetry.State(type: retry,
                                                        requestId: requestId,
                                                        originalRequest: request,
                                                        retryCount: 1)
                        }
                        guard retryState.retryCount <= maximumRetryCount else {
                            break
                        }
                        let urlRequest = addRetryHeaderToRequest(state: retryState)
                        DispatchQueue.global().asyncAfter(deadline: .now() + rateInfo.delay) {
                            self.send(urlRequest, parsing: context, state: retryState, completion: completion)
                        }
                        return
                    }
                    fallthrough
                default:
                    if let error = error(from: data) ?? context?.error(from: data) {
                        throw APIClientError.serverError(error)
                    } else {
                        throw APIClientError.statusCode(httpResponse.statusCode)
                    }
                }
            } catch let error as APIClientError {
                self.didSend(request: request, received: error)
                completion(.failure(error))
            } catch {
                let apiError = APIClientError.cannotParseResponse(error: error)
                self.didSend(request: request, received: apiError)
                completion(.failure(apiError))
            }
        }.resume()
    }
    
    private func addRetryHeaderToRequest(state: APIRetry.State) -> URLRequest {
        var request = state.originalRequest
        request.allHTTPHeaderFields?.updateValue(state.requestId, forKey: "x-okta-request-id")
        request.allHTTPHeaderFields?.updateValue(state.retryCount.stringValue, forKey: "x-okta-retry-count")
        return request
    }
}

extension APIClient {
    private func relatedLinks<T>(from linkHeader: String?) -> [APIResponse<T>.Link: URL] {
        guard let linkHeader = linkHeader,
              let matches = linkRegex?.matches(in: linkHeader, options: [], range: NSMakeRange(0, linkHeader.count))
        else {
            return [:]
        }
        
        var links: [APIResponse<T>.Link: URL] = [:]
        for match in matches {
            guard let urlRange = Range(match.range(at: 1), in: linkHeader),
                  let url = URL(string: String(linkHeader[urlRange])),
                  let keyRange = Range(match.range(at: 2), in: linkHeader),
                  let key = APIResponse<T>.Link(rawValue: String(linkHeader[keyRange]))
            else {
                continue
            }
            
            links[key] = url
        }
        
        return links
    }
    
    private func validate<T>(data: Data, response: HTTPURLResponse, rateInfo: ApiRateLimit?, parsing context: APIParsingContext? = nil) throws -> APIResponse<T> {
        var requestId: String? = nil
        if let requestIdHeader = requestIdHeader {
            requestId = response.allHeaderFields[requestIdHeader] as? String
        }
        
        var date: Date? = nil
        if let dateString = response.allHeaderFields["Date"] as? String {
            date = httpDateFormatter.date(from: dateString)
        }
        
        // swiftlint:disable force_unwrapping
        let jsonData = (data.isEmpty) ? "{}".data(using: .utf8)! : data
        // swiftlint:enable force_unwrapping
        
        return APIResponse(result: try decode(T.self,
                                              from: jsonData,
                                              userInfo: context?.codingUserInfo),
                           date: date ?? Date(),
                           links: relatedLinks(from: response.allHeaderFields["Link"] as? String),
                           rateInfo: rateInfo,
                           requestId: requestId)
    }
}

fileprivate let linkRegex = try? NSRegularExpression(pattern: "<([^>]+)>; rel=\"([^\"]+)\"", options: [])

let httpDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
    return dateFormatter
}()

let defaultIsoDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    return formatter
}()

let defaultJSONEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(defaultIsoDateFormatter)
    if #available(macOS 10.13, iOS 11.0, tvOS 11.0, *) {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    } else {
        encoder.outputFormatting = .prettyPrinted
    }
    return encoder
}()

let defaultJSONDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(defaultIsoDateFormatter)
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
