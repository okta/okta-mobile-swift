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
    
    func interact(completion: @escaping (String?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        let result = response(for: #function)
        completion(result?["handle"] as? String, result?["error"] as? Error)
    }
    
    func introspect(_ interactionHandle: String?, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["interactionHandle": interactionHandle as Any]))
        completion(nil, nil)
    }
    
    func identify(identifier: String, credentials: IDXClient.Credentials, rememberMe: Bool, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "identifier": identifier as Any,
                                            "credentials": credentials as Any,
                                            "rememberMe": rememberMe as Any
                                          ]))
        completion(nil, nil)
    }
    
    func enroll(authenticator: IDXClient.Authenticator, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["authenticator": authenticator as Any]))
        completion(nil, nil)
    }
    
    func challenge(authenticator: IDXClient.Authenticator, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["authenticator": authenticator as Any]))
        completion(nil, nil)
    }
    
    func answerChallenge(credentials: IDXClient.Credentials, completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: ["credentials": credentials as Any]))
        completion(nil, nil)
    }
    
    func cancel(completion: @escaping (Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function, arguments: nil))
        completion(nil)
    }
    
    func token(url: String, grantType: String, interactionCode: String, completion: @escaping (IDXClient.Token?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "url": url as Any,
                                            "grantType": grantType as Any,
                                            "interactionCode": interactionCode as Any
                                          ]))
        completion(nil, nil)
    }
    
    func proceed(remediation option: IDXClient.Remediation.Option, data: [String : Any], completion: @escaping (IDXClient.Response?, Error?) -> Void) {
        recordedCalls.append(RecordedCall(function: #function,
                                          arguments: [
                                            "remediation": option as Any,
                                            "data": data as Any
                                          ]))
        completion(nil, nil)
    }
}
