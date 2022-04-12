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

public protocol APIRequest {
    associatedtype ResponseType: Decodable

    var httpMethod: APIRequestMethod { get }
    var url: URL { get }
    var query: [String: APIRequestArgument?]? { get }
    var headers: [String: APIRequestArgument?]? { get }
    var acceptsType: APIContentType? { get }
    var contentType: APIContentType? { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var timeoutInterval: TimeInterval { get }
    var authorization: APIAuthorization? { get }

    func body() throws -> Data?
    func request(for client: APIClient) throws -> URLRequest
    func send(to client: APIClient, parsing context: APIParsingContext?, completion: @escaping(Result<APIResponse<ResponseType>, APIClientError>) -> Void)

    #if swift(>=5.5.1)
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
    func send(to client: APIClient, parsing context: APIParsingContext?) async throws -> APIResponse<ResponseType>
    #endif
}

public enum APIRequestMethod: String {
    case get = "GET"
    case delete = "DELETE"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}

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
}

public protocol APIAuthorization {
    var authorizationHeader: String? { get }
}

public protocol APIRequestBody {
    var bodyParameters: [String: Any]? { get }
}

public protocol APIParsingContext {
    var codingUserInfo: [CodingUserInfoKey: Any]? { get }
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
        
        components.queryItems = query?
            .map { ($0.key, $0.value?.stringValue) }
            .filter { $0.1 != nil }
            .map { URLQueryItem(name: $0.0, value: $0.1) }
            .sorted(by: { $0.name < $1.name })

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
            request.setValue(acceptsType.rawValue, forHTTPHeaderField: "Accepts")
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
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8, *)
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

        switch self {
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

