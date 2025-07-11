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

public protocol APIClientConfiguration: Sendable {
    var baseURL: URL { get }
}

/// Protocol defining the interfaces and capabilities that API clients can conform to.
///
/// This provides a common pattern for network operations to be performed, and to centralize boilerplate handling of URL requests, provide customization extensions, and normalize response processing and argument handling.
public protocol APIClient: Sendable {
    /// The base URL requests are performed against.
    ///
    /// This is used when request types may define their path as relative, and can inherit the URL they should be sent to through the client.
    var baseURL: URL { get }
    
    /// The URLSession requests are sent through.
    var session: any URLSessionProtocol { get }

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
    func decode<T: Decodable>(_ type: T.Type, from data: Data, parsing context: (any APIParsingContext)?) throws -> T
    
    /// Parses HTTP response body data when a request fails.
    /// - Returns: Error instance, if any, described within the data.
    func error(from data: Data) -> (any Error)?
    
    /// Invoked immediately prior to a URLRequest being converted to a DataTask.
    func willSend(request: inout URLRequest)
    
    /// Invoked when a request fails.
    func didSend(request: URLRequest, received error: APIClientError, requestId: String?, rateLimit: APIRateLimit?)

    /// Invoked when a request receives an HTTP response.
    func didSend(request: URLRequest, received response: HTTPURLResponse)
    
    /// Invoked when a request returns a successful response.
    func didSend<T>(request: URLRequest, received response: APIResponse<T>)
    
    /// Send the given URLRequest.
    func send<T: Decodable>(_ request: URLRequest, parsing context: (any APIParsingContext)?) async throws -> APIResponse<T>
    
    /// Provides the ``APIRetry`` configurations from the delegate in response to a retry request.
    func shouldRetry(request: URLRequest, rateLimit: APIRateLimit) -> APIRetry
}

/// Protocol that delegates of APIClient instances can conform to.
public protocol APIClientDelegate: AnyObject, Sendable {
    /// Invoked immediately prior to a URLRequest being converted to a DataTask.
    func api(client: any APIClient, willSend request: inout URLRequest)
    
    /// Invoked when a request fails.
    func api(client: any APIClient, didSend request: URLRequest, received error: APIClientError, requestId: String?, rateLimit: APIRateLimit?)
    
    /// Invoked when a request returns a successful response.
    func api(client: any APIClient, didSend request: URLRequest, received response: HTTPURLResponse)

    /// Invoked when a request returns a successful response.
    func api<T>(client: any APIClient, didSend request: URLRequest, received response: APIResponse<T>)
    
    /// Provides the APIRetry configurations from the delegate in responds to a retry request.
    func api(client: any APIClient, shouldRetry request: URLRequest) -> APIRetry
}

extension APIClientDelegate {
    public func api(client: any APIClient, willSend request: inout URLRequest) {}
    public func api(client: any APIClient, didSend request: URLRequest, received error: APIClientError, requestId: String?, rateLimit: APIRateLimit?) {}
    public func api(client: any APIClient, didSend request: URLRequest, received response: HTTPURLResponse) {}
    public func api<T>(client: any APIClient, didSend request: URLRequest, received response: APIResponse<T>) {}
    public func api(client: any APIClient, shouldRetry request: URLRequest) -> APIRetry {
        return .default
    }
}

/// List of retry options
public enum APIRetry: Sendable {
    /// Indicates the APIRequest should not be retried.
    case doNotRetry
    
    /// The APIRequest should be retried, up to the given maximum number of times.
    case retry(maximumCount: Int)
    
    /// The default retry option.
    public static let `default` = APIRetry.retry(maximumCount: 3)
    
    struct State: Sendable {
        let type: APIRetry
        let requestId: String?
        let originalRequest: URLRequest
        let retryCount: Int
        
        func nextState() -> State {
            APIRetry.State(type: type,
                           requestId: requestId,
                           originalRequest: originalRequest,
                           retryCount: retryCount + 1)
        }
    }
}

/// Defines the possible results for an API request.
public enum APIResponseResult: Sendable {
    /// Indicates the request was successful.
    case success
    /// The server is indicating the request should be retried.
    case retry
    /// The server reports the response represents an error.
    case error

    init(statusCode: Int) {
        switch statusCode {
        case 200..<300:
            self = .success
        case 429:
            self = .retry
        default:
            self = .error
        }
    }
}

extension APIClient {
    public var additionalHttpHeaders: [String: String]? { nil }
    public var requestIdHeader: String? { "x-okta-request-id" }
    public var userAgent: String { SDKVersion.userAgent }
    
    public func error(from data: Data) -> (any Error)? {
        defaultJSONDecoder.userInfo = [:]
        return try? defaultJSONDecoder.decode(OktaAPIError.self, from: data)
    }
    
    public func willSend(request: inout URLRequest) {}
    
    public func didSend(request: URLRequest, received error: APIClientError) {}
    
    public func didSend(request: URLRequest, received response: HTTPURLResponse) {}
    
    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) {}
    
    public func shouldRetry(request: URLRequest, rateLimit: APIRateLimit) -> APIRetry { .default }
    
    // swiftlint:disable closure_body_length
    public func send<T>(_ request: URLRequest,
                        parsing context: (any APIParsingContext)? = nil) async throws -> APIResponse<T>
    {
        var retryState: APIRetry.State?
        var rateInfo: APIRateLimit?
        var requestId: String?
        var urlRequest = request
        willSend(request: &urlRequest)

        do {
            repeat {
                if let retryState = retryState {
                    urlRequest = addRetryHeadersToRequest(state: retryState)
                }
                
                if let delay = rateInfo?.delay {
                    try await Task.sleep(delay: delay)
                }

                let (data, response) = try await session.data(for: urlRequest)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIClientError.invalidResponse
                }
                
                didSend(request: urlRequest, received: httpResponse)
                
                rateInfo = APIRateLimit(with: httpResponse.allHeaderFields)
                let responseType = context?.resultType(from: httpResponse) ?? APIResponseResult(statusCode: httpResponse.statusCode)
                if let requestIdHeader = requestIdHeader {
                    requestId = httpResponse.allHeaderFields[requestIdHeader] as? String
                }

                switch responseType {
                case .success:
                    let response: APIResponse<T> = try validate(data: data,
                                                                response: httpResponse,
                                                                rateInfo: rateInfo,
                                                                parsing: context)
                    didSend(request: request, received: response)
                    return response

                case .retry:
                    guard let rateInfo = rateInfo else {
                        fallthrough
                    }

                    let retry = retryState?.type ?? shouldRetry(request: request,
                                                                rateLimit: rateInfo)

                    switch retry {
                    case .doNotRetry: break
                    case .retry(let maximumCount):
                        let newRetryState = retryState?.nextState() ?? .init(type: retry,
                                                                             requestId: requestId,
                                                                             originalRequest: request,
                                                                             retryCount: 1)
                        
                        if newRetryState.retryCount <= maximumCount {
                            retryState = newRetryState
                            continue
                        }
                    }

                    // Fall-through to the error case if the maximum retry attempt has been reached and if the delay is not calculated.
                    fallthrough

                case .error:
                    if let error = error(from: data) ?? context?.error(from: data) {
                        throw APIClientError.httpError(error)
                    } else {
                        throw APIClientError.statusCode(httpResponse.statusCode)
                    }
                }
            } while retryState != nil
            
            // This condition should not be encountered
            throw APIClientError.unknown
        } catch {
            didSend(request: request, received: APIClientError(error), requestId: requestId, rateLimit: rateInfo)
            throw error
        }
    }
    // swiftlint:enable closure_body_length

    private func addRetryHeadersToRequest(state: APIRetry.State) -> URLRequest {
        var request = state.originalRequest
        if let requestId = state.requestId {
            request.allHTTPHeaderFields?.updateValue(requestId, forKey: "X-Okta-Retry-For")
        }
        request.allHTTPHeaderFields?.updateValue(state.retryCount.stringValue, forKey: "X-Okta-Retry-Count")
        return request
    }
}

extension APIClient {
    private func relatedLinks<T>(from linkHeader: String?) -> [APIResponse<T>.Link: URL] {
        guard let linkHeader = linkHeader,
              let matches = linkRegex?.matches(in: linkHeader, options: [], range: NSRange(location: 0, length: linkHeader.count))
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
    
    private func validate<T>(data: Data, response: HTTPURLResponse, rateInfo: APIRateLimit?, parsing context: (any APIParsingContext)? = nil) throws -> APIResponse<T> {
        var requestId: String?
        if let requestIdHeader = requestIdHeader {
            requestId = response.allHeaderFields[requestIdHeader] as? String
        }
        
        var date: Date?
        if let dateString = response.allHeaderFields["Date"] as? String {
            date = httpDateFormatter.date(from: dateString)
        }
        
        // swiftlint:disable force_unwrapping
        let jsonData = (data.isEmpty) ? "{}".data(using: .utf8)! : data
        // swiftlint:enable force_unwrapping
        
        return APIResponse(result: try decode(T.self,
                                              from: jsonData,
                                              parsing: context),
                           responseBody: data,
                           date: date ?? Date(),
                           statusCode: response.statusCode,
                           links: relatedLinks(from: response.allHeaderFields["Link"] as? String),
                           rateInfo: rateInfo,
                           requestId: requestId)
    }
}

private let linkRegex = try? NSRegularExpression(pattern: "<([^>]+)>; rel=\"([^\"]+)\"", options: [])

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
