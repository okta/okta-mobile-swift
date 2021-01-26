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

#endif
