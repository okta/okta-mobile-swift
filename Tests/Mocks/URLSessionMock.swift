//
//  URLSessionMock.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-14.
//

import Foundation
@testable import OktaIdx

extension IDXClient.Response {
    class func response(client: IDXClientAPIImpl,
                        folderName: String? = nil,
                        fileName: String) throws -> IDXClient.Response
    {
        let bundle = Bundle(for: URLSessionMock.self)
        guard let path = bundle.url(forResource: fileName,
                                    withExtension: "json",
                                    subdirectory: folderName) else {
            throw IDXClientError.invalidHTTPResponse
        }
        
        let data = try Data(contentsOf: path)
        
        let response = try JSONDecoder.idxResponseDecoder.decode(IDXClient.APIVersion1.Response.self, from: data)
        return IDXClient.Response(client: client, v1: response)
    }
}

class URLSessionMock: URLSessionProtocol {
    struct Call {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }
    
    private var calls: [String: Call] = [:]
    func expect(_ url: String, call: Call) {
        calls[url] = call
    }
    
    func expect(_ url: String,
                data: Data?,
                statusCode: Int = 200,
                contentType: String = "application/x-www-form-urlencoded",
                error: Error? = nil)
    {
        let response = HTTPURLResponse(url: URL(string: url)!,
                                       statusCode: statusCode,
                                       httpVersion: "http/1.1",
                                       headerFields: ["Content-Type": contentType])
        
        expect(url, call: Call(data: data,
                               response: response,
                               error: error))
    }

    func expect(_ url: String,
                folderName: String? = nil,
                fileName: String,
                statusCode: Int = 200,
                contentType: String = "application/x-www-form-urlencoded",
                error: Error? = nil) throws
    {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.url(forResource: fileName, withExtension: "json", subdirectory: folderName) else {
            return
        }
        
        let data = try Data(contentsOf: path)
        
        expect(url,
               data: data,
               statusCode: statusCode,
               contentType: contentType,
               error: error)
    }

    func call(for url: String) -> Call? {
        return calls.removeValue(forKey: url)
    }
    
    func dataTaskWithRequest(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        let response = call(for: request.url!.absoluteString)
        return URLSessionDataTaskMock(data: response?.data,
                                      response: response?.response,
                                      error: response?.error,
                                      completionHandler: completionHandler)
    }
}

class URLSessionDataTaskMock: URLSessionDataTaskProtocol {
    let completionHandler: (Data?, HTTPURLResponse?, Error?) -> Void
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error?
    
    init(data: Data?,
         response: HTTPURLResponse?,
         error: Error?,
         completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
    {
        self.completionHandler = completionHandler
        self.data = data
        self.response = response
        self.error = error
    }
    
    func resume() {
        self.completionHandler(data, response, error)
    }
}
