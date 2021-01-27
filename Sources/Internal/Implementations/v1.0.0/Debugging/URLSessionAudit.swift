//
//  URLSessionAudit.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2021-01-22.
//

import Foundation

#if targetEnvironment(simulator) && DEBUG

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
        let requestBody: Data?
        let responseBody: Data?
        
        init(with request: URLRequest, response: URLResponse?, body data: Data?) {
            date = Date()
            url = request.url
            method = request.httpMethod
            requestBody = request.httpBody
            if let httpResponse = response as? HTTPURLResponse {
                headers = httpResponse.allHeaderFields
                statusCode = httpResponse.statusCode
            } else {
                headers = nil
                statusCode = nil
            }
            responseBody = data
        }

        var description: String {
            let requestString: String
            if let body = requestBody {
                requestString = String(data: body, encoding: .utf8) ?? "<invalid data>"
            } else {
                requestString = "<no request body>"
            }

            let responseString: String
            if let body = responseBody {
                responseString = String(data: body, encoding: .utf8) ?? "<invalid data>"
            } else {
                responseString = "<no response body>"
            }
            
            return "\(method ?? "<null>") \(url?.absoluteString ?? "<null>")\nRequest Body:\n\(requestString)\nStatus code: \(statusCode ?? 0)\n\(responseString)\n"
        }
    }
    
    public var description: String {
        return logs
            .map { $0.description }
            .joined(separator: "\n")
    }
}

#endif
