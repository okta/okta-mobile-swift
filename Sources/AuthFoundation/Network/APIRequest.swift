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

/// Abstract protocol defining the structure of an API request.
public protocol APIRequest {
    associatedtype ResponseType: Decodable
    
    /// HTTP method to perform.
    var httpMethod: APIRequestMethod { get }
    
    /// The URL to perform the API request against.
    var url: URL { get }
    
    /// Optional query string arguments.
    var query: [String: APIRequestArgument?]? { get }
    
    /// Optional HTTP headers to supply.
    var headers: [String: APIRequestArgument?]? { get }
    
    /// Optional accept type to request.
    var acceptsType: APIContentType? { get }
    
    /// Optional request body content type.
    var contentType: APIContentType? { get }
    
    /// The HTTP request cache policy to use.
    var cachePolicy: URLRequest.CachePolicy { get }
    
    /// The HTTP timeout interval.
    var timeoutInterval: TimeInterval { get }
    
    /// Optional API authorization information to use.
    var authorization: APIAuthorization? { get }
    
    /// Function to generate the HTTP request body.
    /// - Returns: Data for the body, or `nil` if no body is needed.
    func body() throws -> Data?
    
    /// Composes a URLRequest for this object.
    /// - Parameter client: The ``APIClient`` the request is being sent through.
    /// - Returns: URLRequest instance for this API request.
    func request(for client: APIClient) throws -> URLRequest
    
    /// Sends the request to the given ``APIClient``.
    /// - Parameters:
    ///   - client: ``APIClient`` the request is being sent to.
    ///   - context: Optional context to use when parsing the response.
    ///   - completion: Completion block invoked with the result.
    func send(to client: APIClient, parsing context: APIParsingContext?, completion: @escaping(Result<APIResponse<ResponseType>, APIClientError>) -> Void)

    #if swift(>=5.5.1)
    /// Asynchronously sends the request to the given ``APIClient``.
    /// - Parameters:
    ///   - client: ``APIClient`` the request is being sent to.
    ///   - context: Optional context to use when parsing the response.
    /// - Returns: ``APIResponse`` result of the request.
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    func send(to client: APIClient, parsing context: APIParsingContext?) async throws -> APIResponse<ResponseType>
    #endif
}

/// API HTTP request method.
public enum APIRequestMethod: String {
    case get = "GET"
    case delete = "DELETE"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}

/// Describes the ``APIRequest`` content type.
public enum APIContentType: Equatable, RawRepresentable {
    case json
    case formEncoded
    case other(_ type: String)

    public typealias RawValue = String
    public init?(rawValue: String) {
        if "application/json" ~= rawValue {
            self = .json
        } else if "application/x-www-form-urlencoded" ~= rawValue {
            self = .formEncoded
        } else {
            self = .other(rawValue)
        }
    }
    
    var underlyingType: APIContentType? {
        switch self {
        case .other(let value):
            if value.hasPrefix("application/json") ||
                value.hasPrefix("application/ion+json")
            {
                return .json
            } else if value.hasPrefix("application/x-www-form-urlencoded") {
                return .formEncoded
            } else {
                return self
            }
        default:
            return self
        }
    }
}

/// Defines how ``APIRequest`` authorization headers are generated.
public protocol APIAuthorization {
    /// The value of the authorization header, or `nil` if none should be set.
    var authorizationHeader: String? { get }
}

/// Defines key/value pairs for an ``APIRequest`` body.
public protocol APIRequestBody {
    /// Key/value pairs to use when generating an ``APIRequest`` body.
    var bodyParameters: [String: Any]? { get }
}

/// Provides contextual information when parsing and decoding ``APIRequest`` responses, or errors.
public protocol APIParsingContext {
    /// Optional coding user info to use when parsing ``APIRequest`` responses.
    var codingUserInfo: [CodingUserInfoKey: Any]? { get }
    
    /// Enables the response from an ``APIRequest`` to be customized.
    ///
    /// The default implementation utilizes the response's status code to report the appropriate result.
    /// - Parameter response: The response returned from the server.
    /// - Returns: The result that should be inferred from this response.
    func resultType(from response: HTTPURLResponse) -> APIResponseResult
    
    /// Generates an error response from an ``APIRequest`` result when an HTTP error occurs.
    /// - Parameter data: Raw data returned from the HTTP response.
    /// - Returns: Optional error option described within the supplied data.
    func error(from data: Data) -> Error?
}

extension APIParsingContext {
    public func error(from data: Data) -> Error? { nil }
    public func resultType(from response: HTTPURLResponse) -> APIResponseResult {
        APIResponseResult(statusCode: response.statusCode)
    }
}

extension APIRequest where Self: APIRequestBody {
    public func body() throws -> Data? {
        try contentType?.encodedData(with: bodyParameters)
    }
}

extension APIRequest where Self: Encodable {
    public func body() throws -> Data? {
        guard let contentType = contentType else {
            return nil
        }
        
        guard contentType == .json else {
            throw APIClientError.unsupportedContentType(contentType)
        }
        
        return try defaultJSONEncoder.encode(self)
    }
}

extension APIRequest {
    public var httpMethod: APIRequestMethod { .get }
    public var query: [String: APIRequestArgument?]? { nil }
    public var headers: [String: APIRequestArgument?]? { nil }
    public var acceptsType: APIContentType? { nil }
    public var contentType: APIContentType? { nil }
    public var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringLocalAndRemoteCacheData }
    public var timeoutInterval: TimeInterval { 60 }
    public var authorization: APIAuthorization? { nil }

    public func body() throws -> Data? { nil }
    public func request(for client: APIClient) throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            throw APIClientError.invalidUrl
        }
        
        components.percentEncodedQuery = query?.percentQueryEncoded

        guard let requestUrl = components.url else {
            throw APIClientError.invalidUrl
        }
        
        var request = URLRequest(url: requestUrl,
                                 cachePolicy: cachePolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = httpMethod.rawValue
        headers?.forEach { (key, value) in
            guard let value = value?.stringValue else { return }
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let authorization = authorization?.authorizationHeader {
            request.addValue(authorization, forHTTPHeaderField: "Authorization")
        }
        
        if let contentType = contentType {
            request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        }
        
        if let acceptsType = acceptsType {
            request.setValue(acceptsType.rawValue, forHTTPHeaderField: "Accept")
        }
        
        request.setValue(client.userAgent, forHTTPHeaderField: "User-Agent")

        client.additionalHttpHeaders?.forEach { (key, value) in
            request.addValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = try body()
        
        return request
    }
    
    public func send(to client: APIClient, parsing context: APIParsingContext? = nil, completion: @escaping(Result<APIResponse<ResponseType>, APIClientError>) -> Void) {
        do {
            let urlRequest = try request(for: client)
            client.send(urlRequest,
                        parsing: context ?? self as? APIParsingContext,
                        completion: completion)
        } catch {
            completion(.failure(.serverError(error)))
        }
    }
    
    #if swift(>=5.5.1)
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6, *)
    public func send(to client: APIClient, parsing context: APIParsingContext? = nil) async throws -> APIResponse<ResponseType> {
        try await withCheckedThrowingContinuation { continuation in
            send(to: client, parsing: context) { result in
                continuation.resume(with: result)
            }
        }
    }
    #endif
}

extension APIContentType {
    public var rawValue: String {
        switch self {
        case .json:
            return "application/json; charset=UTF-8"
        case .formEncoded:
            return "application/x-www-form-urlencoded; charset=UTF-8"
        case .other(let encoding):
            return encoding
        }
    }
    
    func encodedData(with parameters: [String: Any]?) throws -> Data? {
        guard let parameters = parameters else {
            return nil
        }

        switch self.underlyingType {
        case .formEncoded:
            guard let parameters = parameters as? [String: APIRequestArgument] else {
                throw APIClientError.invalidRequestData
            }
            return URLRequest.oktaURLFormEncodedString(for: parameters)?.data(using: .utf8)
        case .json:
            var opts: JSONSerialization.WritingOptions = []
            if #available(iOS 11.0, iOSApplicationExtension 11.0, tvOS 11.0, macOS 10.13, *) {
                opts.insert(.sortedKeys)
            }
            
            return try JSONSerialization.data(withJSONObject: parameters, options: opts)
        default:
            return nil
        }
    }
}
