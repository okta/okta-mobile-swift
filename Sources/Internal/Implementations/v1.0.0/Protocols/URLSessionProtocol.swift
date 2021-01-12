//
//  URLSessionProtocol.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation

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
        
        guard httpResponse.statusCode == 200 else {
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
