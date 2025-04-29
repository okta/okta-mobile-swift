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
public protocol APIRequest: Sendable {
    associatedtype ResponseType: Decodable & Sendable
    
    /// HTTP method to perform.
    var httpMethod: APIRequestMethod { get }
    
    /// The URL to perform the API request against.
    var url: URL { get }
    
    /// Optional query string arguments.
    var query: [String: (any APIRequestArgument)?]? { get }
    
    /// Optional HTTP headers to supply.
    var headers: [String: (any APIRequestArgument)?]? { get }
    
    /// Optional accept type to request.
    var acceptsType: APIContentType? { get }
    
    /// Optional request body content type.
    var contentType: APIContentType? { get }
    
    /// The HTTP request cache policy to use.
    var cachePolicy: URLRequest.CachePolicy { get }
    
    /// The HTTP timeout interval.
    var timeoutInterval: TimeInterval { get }
    
    /// Optional API authorization information to use.
    var authorization: (any APIAuthorization)? { get }
    
    /// Function to generate the HTTP request body.
    /// - Returns: Data for the body, or `nil` if no body is needed.
    func body() throws -> Data?
    
    /// Composes a URLRequest for this object.
    /// - Parameter client: The ``APIClient`` the request is being sent through.
    /// - Returns: URLRequest instance for this API request.
    func request(for client: any APIClient) throws -> URLRequest
    
    /// Asynchronously sends the request to the given ``APIClient``.
    /// - Parameters:
    ///   - client: ``APIClient`` the request is being sent to.
    ///   - context: Optional context to use when parsing the response.
    /// - Returns: ``APIResponse`` result of the request.
    func send(to client: any APIClient, parsing context: (any APIParsingContext)?) async throws -> APIResponse<ResponseType>
}

/// API HTTP request method.
public enum APIRequestMethod: String, Sendable {
    case get = "GET"
    case delete = "DELETE"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}

/// Describes the ``APIRequest`` content type.
public enum APIContentType: Sendable, Equatable, RawRepresentable {
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
    var bodyParameters: [String: any APIRequestArgument]? { get }
}

/// Provides contextual information when parsing and decoding ``APIRequest`` responses, or errors.
public protocol APIParsingContext: Sendable {
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
    func error(from data: Data) -> (any Error)?
}

extension APIParsingContext {
    @_documentation(visibility: private)
    public var codingUserInfo: [CodingUserInfoKey: Any]? {
        if let flowRequest = self as? any AuthenticationFlowRequest,
           let persistValues = flowRequest.context.persistValues,
           !persistValues.isEmpty
        {
            return [ .clientSettings: persistValues ]
        }
        
        return nil
    }

    @_documentation(visibility: private)
    public func error(from data: Data) -> (any Error)? { nil }

    @_documentation(visibility: private)
    public func resultType(from response: HTTPURLResponse) -> APIResponseResult {
        APIResponseResult(statusCode: response.statusCode)
    }
}

extension APIRequest where Self: APIRequestBody {
    public func body() throws -> Data? {
        try contentType?.encodedData(with: bodyParameters?.stringComponents)
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
    public var query: [String: (any APIRequestArgument)?]? { nil }
    public var headers: [String: (any APIRequestArgument)?]? { nil }
    public var acceptsType: APIContentType? { nil }
    public var contentType: APIContentType? { nil }
    public var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringLocalAndRemoteCacheData }
    public var timeoutInterval: TimeInterval { 60 }
    public var authorization: (any APIAuthorization)? { nil }

    public func body() throws -> Data? { nil }
    public func request(for client: any APIClient) throws -> URLRequest {
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
    
    public func send(to client: any APIClient, parsing context: (any APIParsingContext)? = nil) async throws -> APIResponse<ResponseType> {
        try await client.send(try request(for: client),
                              parsing: context ?? self as? (any APIParsingContext))
    }
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
    
    func encodedData(with parameters: [String: any Sendable]?) throws -> Data? {
        guard let parameters = parameters else {
            return nil
        }

        switch self.underlyingType {
        case .formEncoded:
            guard let parameters = parameters as? [String: any APIRequestArgument] else {
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
