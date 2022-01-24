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
    var additionalHttpHeaders: [String:String]? { get }
    
    /// The name of the HTTP response header where unique request IDs can be found.
    var requestIdHeader: String? { get }
    
    /// The User-Agent string to be sent along with all outgoing requests.
    var userAgent: String { get }
    
    /// Decodes HTTP response data into an expected type.
    ///
    /// The userInfo property may be included, which can include contextual information that can help decoders formulate objects.
    /// - Returns: Decoded object.
    func decode<T: Decodable>(_ type: T.Type, from data: Data, userInfo: [CodingUserInfoKey:Any]?) throws -> T
    
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

    #if swift(>=5.5.1) && !os(Linux)
    /// Asynchronously send the given URLRequest.
    /// - Returns: APIResponse when the request is successful.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    func send<T: Decodable>(_ request: URLRequest, parsing context: APIParsingContext?) async throws -> APIResponse<T>
    #endif
}

/// Protocol that delegates of APIClient instances can conform to.
public protocol APIClientDelegate: AnyObject {
    /// Invoked immediately prior to a URLRequest being converted to a DataTask.
    func api(client: APIClient, willSend request: inout URLRequest)

    /// Invoked when a request fails.
    func api(client: APIClient, didSend request: URLRequest, received error: APIClientError)

    /// Invoked when a request returns a successful response.
    func api<T>(client: APIClient, didSend request: URLRequest, received response: APIResponse<T>)
}

extension APIClientDelegate {
    public func api(client: APIClient, willSend request: inout URLRequest) {}
    public func api(client: APIClient, didSend request: URLRequest, received error: APIClientError) {}
    public func api<T>(client: APIClient, didSend request: URLRequest, received response: APIResponse<T>) {}
}

extension APIClient {
    public var additionalHttpHeaders: [String:String]? { nil }
    public var requestIdHeader: String? { "x-okta-request-id" }
    public var userAgent: String { SDKVersion.userAgent }
    
    public func decode<T>(_ type: T.Type, from data: Data, userInfo: [CodingUserInfoKey:Any]? = nil) throws -> T where T: Decodable {
        var info: [CodingUserInfoKey:Any] = userInfo ?? [:]
        if info[.baseURL] == nil {
            info[.baseURL] = baseURL
        }
        
        let jsonDecoder: JSONDecoder
        if let jsonType = type as? JSONDecodable.Type {
            jsonDecoder = jsonType.jsonDecoder
        } else {
            jsonDecoder = defaultJSONDecoder
        }
        
        jsonDecoder.userInfo = info
        
        return try jsonDecoder.decode(type, from: data)
    }
    
    public func error(from data: Data) -> Error? {
        defaultJSONDecoder.userInfo = [:]
        return try? defaultJSONDecoder.decode(OktaAPIError.self, from: data)
    }

    public func willSend(request: inout URLRequest) {}
    
    public func didSend(request: URLRequest, received error: APIClientError) {}

    public func didSend<T>(request: URLRequest, received response: APIResponse<T>) {}

    public func send<T>(_ request: URLRequest, parsing context: APIParsingContext? = nil, completion: @escaping (Result<APIResponse<T>, APIClientError>) -> Void) {
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
                let response: APIResponse<T> = try self.validate(data: data,
                                                                 response: response,
                                                                 parsing: context)
                self.didSend(request: request, received: response)
                
                completion(.success(response))
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
    
    /// Convenience method that enables the use of an ``APIRequest`` struct to define how a network operation should be performed.
    public func send<T>(_ request: APIRequest, parsing context: APIParsingContext? = nil, completion: @escaping (Result<APIResponse<T>, APIClientError>) -> Void) {
        do {
            let urlRequest = try request.request(for: self)
            send(urlRequest,
                 parsing: context ?? request as? APIParsingContext,
                 completion: completion)
        } catch {
            completion(.failure(.serverError(error)))
        }
    }

    #if swift(>=5.5.1) && !os(Linux)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    public func send<T>(_ request: URLRequest, parsing context: APIParsingContext? = nil) async throws -> APIResponse<T> {
        var urlRequest = request
        willSend(request: &urlRequest)

        let (data, response) = try await session.data(for: urlRequest, delegate: nil)
        let result: APIResponse<T>
        do {
            result = try validate(data: data,
                                  response: response,
                                  parsing: context)
            self.didSend(request: request, received: result)
        } catch let error as APIClientError {
            self.didSend(request: request, received: error)
            throw error
        } catch {
            let apiError = APIClientError.cannotParseResponse(error: error)
            self.didSend(request: request, received: apiError)
            throw apiError
        }

        return result
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, *)
    public func send<T>(_ request: APIRequest, parsing context: APIParsingContext? = nil) async throws -> APIResponse<T> {
        try await send(try request.request(for: self),
                       parsing: context ?? request as? APIParsingContext)
    }
    #endif
}

extension APIClient {
    private func relatedLinks<T>(from linkHeader: String?) -> [APIResponse<T>.Link:URL] {
        guard let linkHeader = linkHeader,
           let matches = linkRegex?.matches(in: linkHeader, options: [], range: NSMakeRange(0, linkHeader.count))
        else {
            return [:]
        }
        
        var links: [APIResponse<T>.Link:URL] = [:]
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
    
    private func validate<T>(data: Data, response: URLResponse, parsing context: APIParsingContext? = nil) throws -> APIResponse<T> {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            if let error = error(from: data) {
                throw APIClientError.serverError(error)
            } else {
                throw APIClientError.statusCode(httpResponse.statusCode)
            }
        }
        
        var requestId: String? = nil
        if let requestIdHeader = requestIdHeader {
            requestId = httpResponse.allHeaderFields[requestIdHeader] as? String
        }
        
        var date: Date? = nil
        if let dateString = httpResponse.allHeaderFields["Date"] as? String {
            date = httpDateFormatter.date(from: dateString)
        }
        
        let rateInfo = APIResponse<T>.RateLimit(with: httpResponse.allHeaderFields)
        
        let jsonData = (data.isEmpty) ? "{}".data(using: .utf8)! : data
        return APIResponse(result: try decode(T.self,
                                              from: jsonData,
                                              userInfo: context?.codingUserInfo),
                           date: date ?? Date(),
                           links: relatedLinks(from: httpResponse.allHeaderFields["Link"] as? String),
                           rateInfo: rateInfo,
                           requestId: requestId)
    }
}

fileprivate let linkRegex = try? NSRegularExpression(pattern: "<([^>]+)>; rel=\"([^\"]+)\"", options: [])

fileprivate let httpDateFormatter: DateFormatter = {
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

fileprivate let defaultJSONDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(defaultIsoDateFormatter)
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
