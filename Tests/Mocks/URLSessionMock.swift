/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation
@testable import OktaIdx

extension IDXClient.Response {
    class func response(api: IDXClientAPIImpl,
                        folderName: String? = nil,
                        fileName: String) throws -> IDXClient.Response
    {
        let path = Bundle.testResource(folderName: folderName, fileName: fileName)
        let data: Data!
        do {
            data = try Data(contentsOf: path)
        } catch {
            throw IDXClientError.invalidHTTPResponse
        }
        
        let response = try JSONDecoder.idxResponseDecoder.decode(IDXClient.APIVersion1.Response.self, from: data)
        return IDXClient.Response(api: api, v1: response)
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
        let path = Bundle.testResource(folderName: folderName, fileName: fileName)
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
