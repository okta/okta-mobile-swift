//
//  IDXClientDelegateRecorder.swift
//  okta-idx-ios-tests
//
//  Created by Mike Nachbaur on 2021-02-04.
//

import Foundation
import OktaIdx

class DelegateRecorder: IDXClientDelegate {
    struct Call {
        enum CallType {
            case error
            case response
            case token
        }
        
        let type: CallType
        let object: AnyObject?
        let isMainThread: Bool = {
            Thread.isMainThread
        }()
        
        var response: IDXClient.Response? {
            guard let result = object as? IDXClient.Response else { return nil }
            return result
        }

        var token: IDXClient.Token? {
            guard let result = object as? IDXClient.Token else { return nil }
            return result
        }
    }
    
    private(set) var calls: [Call] = []
    
    func reset() {
        calls.removeAll()
    }
    
    func idx(client: IDXClient, receivedError: Error) {
        calls.append(Call(type: .error, object: nil))
    }
    
    func idx(client: IDXClient, didReceive response: IDXClient.Response) {
        calls.append(Call(type: .response, object: response))
    }
    
    func idx(client: IDXClient, didExchangeToken token: IDXClient.Token) {
        calls.append(Call(type: .token, object: token))
    }
}
