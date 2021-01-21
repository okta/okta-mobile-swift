//
//  URLSessionProtocol.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

public class URLSessionAudit: CustomStringConvertible {
    static let shared = URLSessionAudit()
    private let queue = DispatchQueue(label: "com.okta.urlsession.audit")
    private var logs: [Log] = []
    
    func reset() {
        queue.sync {
            self.logs.removeAll()
        }
    }
    
    internal func add(log item: Log) {
        queue.async {
            self.logs.append(item)
        }
    }
    
    struct Log: CustomStringConvertible {
        let date: Date
        let url: URL?
        let method: String?
        let headers: [AnyHashable:Any]?
        let statusCode: Int?
        let body: Data?
        
        init(with request: URLRequest, response: URLResponse?, body data: Data?) {
            date = Date()
            url = request.url
            method = request.httpMethod
            if let httpResponse = response as? HTTPURLResponse {
                headers = httpResponse.allHeaderFields
                statusCode = httpResponse.statusCode
            } else {
                headers = nil
                statusCode = nil
            }
            body = data
        }

        var description: String {
            let bodyString: String
            if let body = body {
                bodyString = String(data: body, encoding: .utf8) ?? "<invalid data>"
            } else {
                bodyString = "<no body>"
            }
            return "\(method ?? "<null>") \(url?.absoluteString ?? "<null>")\nStatus code: \(statusCode ?? 0)\n\(bodyString)\n"
        }
    }
    
    public var description: String {
        return logs
            .map { $0.description }
            .joined(separator: "\n")
    }
}

protocol URLSessionProtocol {
    typealias DataTaskResult = (Data?, HTTPURLResponse?, Error?) -> Void
    func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSession: URLSessionProtocol {
    func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: { (data, response, error) in
            URLSessionAudit.shared.add(log: .init(with: request, response: response, body: data))
            
            self.handleDataTaskRequest(data: data,
                                       response: response,
                                       error: error,
                                       completionHandler: completionHandler)
        }) as URLSessionDataTaskProtocol
    }
    
    internal func handleDataTaskRequest(data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping DataTaskResult) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(data, nil, IDXClientError.invalidHTTPResponse)
            return
        }
        
        guard error == nil else {
            completionHandler(data, httpResponse, error)
            return
        }
        
        guard httpResponse.statusCode <= 400 else {
            completionHandler(data, httpResponse, IDXClientError.invalidHTTPResponse)
            return
        }

        completionHandler(data, httpResponse, nil)
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLRequest {
    static func idxURLFormEncodedString(for params: [String:String]) -> String? {
        func escape(_ str: String) -> String {
            return str.replacingOccurrences(of: "\n", with: "\r\n")
                .addingPercentEncoding(withAllowedCharacters: idxQueryCharacters)!
                .replacingOccurrences(of: " ", with: "+")
        }

        return params.keys.sorted().compactMap {
            escape($0) + "=" + escape(params[$0]!)
        }.joined(separator: "&")
    }
    
    private static let idxQueryCharacters: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.insert(" ")
        allowed.remove("+")
        allowed.remove("/")
        allowed.remove("&")
        allowed.remove("=")
        allowed.remove("?")
        return allowed
    }()
}
