//
//  IDXClientAPIMock.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2020-12-10.
//

import Foundation
@testable import OktaIdx

class IDXClientAPIv1Mock: IDXClientAPIImpl {
    let configuration: IDXClient.Configuration
    
    struct RecordedCall {
        let function: String
        let arguments: [String:Any]?
    }
    static var version = IDXClient.Version.v1_0_0
    var recordedCalls: [RecordedCall] = []
    func reset() {
        recordedCalls.removeAll()
    }
    
    private var expectations: [String:[String:Any]] = [:]
    func expect(function name: String, arguments: [String:Any]) {
        expectations[name] = arguments
    }
    
    private func response(for name: String) -> [String:Any]? {
        return expectations.removeValue(forKey: name)
    }
    
    weak var delegate: IDXClientAPIDelegate?
    
    init(configuration: IDXClient.Configuration) {
        self.configuration = configuration
    }
    
    func start(completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }
        
    func cancel(completion: @escaping (Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        completion(nil)
    }
    
    func proceed(remediation option: IDXClient.Remediation.Option, data: [String : Any]?, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                            "data": data ?? [:] as Any
                                          ]))
        let result = response(for: #function)
        completion(result?["response"] as? IDXClient.Response, result?["error"] as? Error)
    }

    func exchangeCode(using successResponse: IDXClient.Remediation.Option, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "using": successResponse as Any
                                          ]))
        let result = response(for: #function)
        completion(result?["token"] as? IDXClient.Token, result?["error"] as? Error)
    }
}
