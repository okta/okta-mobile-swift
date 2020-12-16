//
//  IDXClient+Response.swift
//  okta-idx-ios
//
//  Created by Mike Nachbaur on 2020-12-15.
//

import Foundation

public extension IDXClient {
    @objc(IDXResponse)
    class Response: NSObject {
        private weak var client: IDXClientAPIImpl?
        
        public let stateHandle: String
        public let version: String
        public let expiresAt: Date
        public let intent: String
        public let remediation: Remediation
        
        internal init(client: IDXClientAPIImpl?, stateHandle: String, version: String, expiresAt: Date, intent: String, remediation: Remediation) {
            self.client = client
            self.stateHandle = stateHandle
            self.version = version
            self.expiresAt = expiresAt
            self.intent = intent
            self.remediation = remediation
            super.init()
        }
        
        public func cancel(completionHandler: @escaping(Response?, Error?) -> Void) {
        }
        public func successWithInteractionCode(completionHandler: @escaping(SuccessResponse?, Error?) -> Void) {
        }
        public func loginSuccess() -> Bool {
            return false
        }
    }
    
    @objc(IDXSuccessResponse)
    class SuccessResponse: NSObject {
        public let rel: String
        public let name: String
        public let method: String
        public let href: URL
        public let accepts: String
        public func form() -> [FormValue] {
            return []
        }
        public func exchangeCode(completionHandler: @escaping (Token?, Error?) -> Void) {
        }
        
        internal init(rel: String,
                      name: String,
                      method: String,
                      href: URL,
                      accepts: String)
        {
            self.rel = rel
            self.name = name
            self.method = method
            self.href = href
            self.accepts = accepts
            
            super.init()
        }

    }
    
    @objc(IDXToken)
    class Token: NSObject {
        public let accessToken: String
        public let expiresIn: TimeInterval
        public let idToken: String
        public let scope: String
        public let tokenType: String

        internal init(accessToken: String,
                      expiresIn: TimeInterval,
                      idToken: String,
                      scope: String,
                      tokenType: String)
        {
            self.accessToken = accessToken
            self.expiresIn = expiresIn
            self.idToken = idToken
            self.scope = scope
            self.tokenType = tokenType
            
            super.init()
        }
    }

    @objc(IDXRemediation)
    class Remediation: NSObject {
        public var type: String
        public let remediationOptions: [Option]
        
        private weak var client: IDXClientAPIImpl?

        internal init(client: IDXClientAPIImpl, type: String, remediationOptions: [Option]) {
            self.client = client
            self.type = type
            self.remediationOptions = remediationOptions
         
            super.init()
        }
        
        @objc(IDXRemediationOption)
        public class Option: NSObject {
            public let rel: [String]
            public let name: String
            public let method: String
            public let href: URL
            public let accepts: String
            public let form: [FormValue]
            
            private weak var client: IDXClientAPIImpl?

            internal init(client: IDXClientAPIImpl,
                          rel: [String],
                          name: String,
                          method: String,
                          href: URL,
                          accepts: String,
                          form: [FormValue])
            {
                self.client = client
                self.rel = rel
                self.name = name
                self.method = method
                self.href = href
                self.accepts = accepts
                self.form = form
                
                super.init()
            }

            public func proceed(with dataFromUI: [String:Any], completionHandler: @escaping (Response?, Error?) -> Void) {
                guard let client = client else {
                    completionHandler(nil, IDXClientAPIError.invalidClient)
                    return
                }
                
                client.proceed(remediation: self, data: dataFromUI, completion: completionHandler)
            }
        }
    }
        
    @objc(IDXFormValue)
    class FormValue: NSObject {
        public let name: String
        public let label: String?
        public let type: String?
        public let value: AnyObject?
        public let visible: Bool
        public let mutable: Bool
        public let required: Bool
        public let secret: Bool
        
        public func relatesTo() -> AnyObject? {
            return nil
        }
        
        public func form() -> [FormValue] {
            return []
        }
        
        public func options() -> [FormValue]? {
            return nil
        }
        
        internal init(name: String,
                      label: String?,
                      type: String?,
                      value: AnyObject?,
                      visible: Bool,
                      mutable: Bool,
                      required: Bool,
                      secret: Bool)
        {
            self.name = name
            self.label = label
            self.type = type
            self.value = value
            self.visible = visible
            self.mutable = mutable
            self.required = required
            self.secret = secret
            
            super.init()
        }
    }
    
}
