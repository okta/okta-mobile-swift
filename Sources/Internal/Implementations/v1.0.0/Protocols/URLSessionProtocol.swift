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
            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler(data, nil, IDXClientAPIError.invalidHTTPResponse)
                return
            }
            
            guard error == nil else {
                completionHandler(data, httpResponse, error)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completionHandler(data, httpResponse, IDXClientAPIError.invalidHTTPResponse)
                return
            }

            completionHandler(data, httpResponse, nil)
        }) as URLSessionDataTaskProtocol
    }
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

extension URLRequest {
    static func idxURLFormEncodedString(for params: [String:String]) -> String? {
        var components = URLComponents()
        components.queryItems = params.keys.compactMap {
            URLQueryItem(name: $0, value: params[$0])
        }
        return components.query
    }
}
